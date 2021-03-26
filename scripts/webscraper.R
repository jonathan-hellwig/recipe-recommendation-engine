library(rvest)
library(glue)
library(purrr)
library(tibble)
library(polite)
library(dplyr)
library(stringr)
library(httr)

get_content <- function(url) {
  session <- polite::bow(url)
  polite::scrape(session)
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
  recipe_links <- session %>%
    get_all_recipe_links(first_page, last_page)
  safe_get_single_recipe_df <- purrr::safely(get_single_recipe_df)
  recipe_list <- purrr::map(recipe_links,
                            ~safe_get_single_recipe_df(session, .x))
  # combined_recipes %>% map("error") %>% purrr::discard(~is.null(.))
  combined_recipes <- recipe_list %>%
    map("result") %>%
    reduce(function(first_list, second_list) {
             purrr::map2(first_list, second_list, dplyr::bind_rows)})
  combined_recipes
}

combined_recipes  <- get_recipes_in_page_range(1,1)

url <- "https://www.kurashiru.com/recipes/3365e1c3-f4e5-4de4-8b04-f1ad19e44f51"
session <- polite::bow(url)
content <- session %>%
  polite::scrape()
content %>%
  html_nodes(".video-tsukurepo-list-body") %>%
  html_text()

response <- GET("https://wapi.kurashiru.com/wapi/video_tsukurepos?",
                query = list(video_id = "3365e1c3-f4e5-4de4-8b04-f1ad19e44f51"))

user_name <- read_html("kurashiru.html") %>%
  html_nodes(".user-name") %>%
  html_attr()
