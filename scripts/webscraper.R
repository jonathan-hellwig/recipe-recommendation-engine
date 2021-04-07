library(rvest)
library(glue)
library(purrr)
library(tibble)
library(polite)
suppressMessages(library(dplyr))
library(stringr)
library(httr)
suppressMessages(library(log4r))

delay_by <- function(f, amount) {
  force(f)
  force(amount)
  function(...) {
    Sys.sleep(amount)
    f(...)
  }
}

log_message <- function(f, path_log_file, starting_message, stopping_message) {
  force(f)
  force(path_log_file)
  force(starting_message)
  force(stopping_message)
  function(...) {
    default_logger <- log4r::logger(appenders =
                                    log4r::file_appender(path_log_file))
    log4r::info(default_logger, starting_message)
    f(...)
    log4r::info(default_logger, stopping_message)
  }
}

scrape_recipe_links <- function(page_number) {
  recipe_links <- vector(mode = "character")
  base_url <- "https://www.kurashiru.com/video_categories/139"
  recipe_links <- rvest::read_html(base_url,
                     query = list(page = page_number)) %>%
    html_nodes(".title") %>%
    html_attr("href")
  recipe_links %>%
    map_chr(~glue("https://www.kurashiru.com", .x))
}

scrape_recipes <- function(recipe_links, path_log_file) {
    scrape_dynamic_page_delayed_log <- scrape_dynamic_page %>%
      delay_by(5) %>%
      log_message(path_log_file,
                  glue::glue("Starting to obtain recipe."),
                  glue::glue("Finished to obtaining recipe."))
    recipe_links %>%
      purrr::map(function(url) {
                  id <- stringr::str_sub(url, start = 35L, end = -1L)
				          scrape_dynamic_page_delayed_log(url, "current_page.html")
                  parse_recipe_html("current_page.html", id)
  })
}

bind_rows_recipe_list <- function(recipe_list) {
  recipe_list %>%
    reduce(function(first_list, second_list) {
             purrr::map2(first_list, second_list, dplyr::bind_rows)})
}

scrape_dynamic_page  <- function(url, output_path) {
  system(glue::glue("google-chrome-stable --log-level=3 --headless --disable-gpu --dump-dom {url} > {output_path}"))
}

parse_recipe_html <- function(html_path, id) {
  content <- rvest::read_html(html_path, encoding = "utf-8")
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
  list(recipes = recepies_df, ingredients = ingredients_df,
       comments = comments_df, categories = categories_df)
}

write_to_db <- function(dataframes) {
  con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                        host = "localhost",
                        port = 5432,
                        dbname = "recipes",
                        user = "jonathan",
                        password = "password")
  table_names <- names(dataframes)
  write_status <- purrr::map2_lgl(dataframes, table_names,
    ~DBI::dbWriteTable(con, .y, .x, append = TRUE, row.names = FALSE))
  DBI::dbDisconnect(con)
  return(write_status)
}

#url <- "https://www.kurashiru.com/recipes/3365e1c3-f4e5-4de4-8b04-f1ad19e44f51"
#output <- get_single_dynamic_recipe_df(url)
#print(output)
#write_to_db(output)
#get_recipes_in_page_range(1, 1)
