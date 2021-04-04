library(rvest)
library(glue)
library(purrr)
library(tibble)
library(polite)
library(dplyr)
library(stringr)
library(httr)
library(log4r)

delay_by <- function(f, amount) {
  force(f)
  force(amount)
  
  function(...) {
    Sys.sleep(amount)
    f(...)
  }
}
get_single_recipe_df <- function(session, url) {

  id <- stringr::str_sub(url, start = 35L, end = -1L)
  content <- polite::nod(session, url) %>%
    scrape()
  title <- content %>%
    html_node(".title") %>%
    html_text()
  cooking_time <- content %>%
    html_node(".cooking-time") %>%
    html_text()
  ingredients <- content %>%
    html_nodes(".ingredient-name") %>%
    html_text()
  ingredients_quantity <- content %>%
    html_nodes(".ingredient-quantity-amount") %>%
    html_text()
  servings <- content %>%
    html_node(".servings") %>%
    html_text()
  instructions <- content %>%
    html_node(".instructions") %>%
    html_text()
  comments_user_name <- content %>%
    html_nodes(".user-name") %>%
    html_text()
  comments_date <- content %>%
    html_nodes(".published_date") %>%
    html_text()
  comments_text <- content %>%
    html_nodes(".video-tsukurepo-list-body") %>%
    html_text()
  keywords <- content %>%
    html_nodes(".tag-text") %>%
    html_text()
  categories <- content %>%
    html_nodes("table.related-video-categories-root") %>%
    html_table()
  recepies_df <- tibble(id = id, recipe_name = title, cooking_time = cooking_time,
                        servings = servings, instructions = instructions)
  ingredients_df <- tibble(id = id, ingredient = ingredients,
                           quantity = ingredients_quantity)
  comments_df <- tibble(id = id, user = comments_user_name,
                        date = comments_date, text = comments_text)
  keywords_df <- tibble(id = id, keyword = keywords)
  categories_df <- categories %>%
    flatten_df() %>%
    mutate(id = id)

  list(recepies_df, ingredients_df, comments_df, categories_df)
}

# Iterate over ever recipe

get_all_recipe_links <- function(session, first_page, last_page) {
  recipe_links <- vector(mode = "character")
  for (current_page in first_page:last_page) {
    response <- scrape(session,
                       query = list(page = current_page)) %>%
    html_nodes(".title") %>%
    html_attr("href")
  recipe_links <- c(recipe_links,
                    map_chr(response,
                            ~glue("https://www.kurashiru.com", .x)))
  }
  recipe_links
}

get_recipes_in_page_range <- function(first_page, last_page) {
  base_url <- "https://www.kurashiru.com/video_categories/139"
  session <- polite::bow(base_url)
  default_logger <- log4r::logger()
  log4r::info(default_logger, "Started obtaining recipe links.")
  recipe_links <- session %>%
    get_all_recipe_links(first_page, last_page)
  log4r::info(default_logger, "Finished obtaining recipe links.")
  get_single_recipe_delayed <- delay_by(get_single_dynamic_recipe_df, 5)
  recipe_list <- purrr::map(recipe_links,
                            ~get_single_recipe_delayed(.x))
  combined_recipes <- recipe_list %>%
    reduce(function(first_list, second_list) {
             purrr::map2(first_list, second_list, dplyr::bind_rows)})
  combined_recipes
}

get_single_dynamic_recipe_df <- function(url) {
  default_logger <- log4r::logger()

  id <- stringr::str_sub(url, start = 35L, end = -1L)

  log4r::info(default_logger, glue::glue("Obtaining recipe with id {id}."))
  system(glue::glue("python scrape_page.py {url} > current_page.html"))

  log4r::info(default_logger, glue::glue("Finished recipe with id {id}."))
  content <- rvest::read_html("current_page.html", encoding = "utf-8")

  title <- content %>%
    html_node(".title") %>%
    html_text() %>%
    str_remove_all("レシピ・作り方|\\s")

  cooking_time <- content %>%
    html_node(".cooking-time") %>%
    html_text() %>%
    map_chr(~str_remove_all(., "調理時間：|\\s"))

  ingredients <- content %>%
    html_nodes(".ingredient-name") %>%
    html_text() %>%
    map_chr(~str_remove_all(., "\\s"))

  ingredients_quantity <- content %>%
    html_nodes(".ingredient-quantity-amount") %>%
    html_text()

  servings <- content %>%
    html_node(".servings") %>%
    html_text() %>%
    str_extract("\\d")

  instructions <- content %>%
    html_node(".instructions") %>%
    html_text() %>%
    map_chr(~str_remove_all(., "\\s"))

  comments_user_name <- content %>%
    html_nodes(".user-name") %>%
    html_text() %>%
    map_chr(~str_remove_all(., "\\s"))

  comments_date <- content %>%
    html_nodes(".published-date") %>%
    html_text() %>%
    map_chr(~str_remove_all(., "\\s"))

  comments_text <- content %>%
    html_nodes(".video-tsukurepo-list-body") %>%
    html_text() %>%
    map_chr(~str_remove_all(., "\\s"))

  keywords <- content %>%
    html_nodes(".tag-text") %>%
    html_text()

  categories <- content %>%
    html_nodes("table.related-video-categories-root") %>%
    html_table()

  recepies_df <- tibble(id = id, recipe_name = title, cooking_time = cooking_time,
                        servings = servings, instructions = instructions)
  ingredients_df <- tibble(id = id, ingredient = ingredients,
                           quantity = ingredients_quantity)
  comments_df <- tibble(id = id, user = comments_user_name,
                        date = comments_date, text = comments_text)
  keywords_df <- tibble(id = id, keyword = keywords)
  categories_df <- categories %>%
    flatten_df() %>%
    mutate(id = id)

  list(recepies_df, ingredients_df, comments_df, categories_df)
}
write_to_db <- function(combined_recipes) {
  con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                        host = "localhost",
                        port = 5432,
                        dbname = "recipes",
                        user = "postgres",
                        password = "")
  table_names <- c("recipe", "ingredients", "comments", "categories")
  purrr::map2_lgl(combined_recipes, table_names,
    ~DBI::dbWriteTable(con, .y, .x, append = TRUE, row.names = FALSE))

}
url <- "https://www.kurashiru.com/recipes/3365e1c3-f4e5-4de4-8b04-f1ad19e44f51"
output <- get_single_dynamic_recipe_df(url)
write_to_db(output)

combined_recipes  <- get_recipes_in_page_range(1, 1)
