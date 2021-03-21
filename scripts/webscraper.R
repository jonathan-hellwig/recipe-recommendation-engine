library(rvest)
library(purrr)
library(tibble)
library(polite)
library(dplyr)

get_content <- function(url) {
  session <- polite::bow(url)
  polite::scrape(session)
}

get_single_recipe_df <- function(url) {

  content <- get_content(url)
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
  recepies_df <- tibble(recipe_name = title, cooking_time = cooking_time,
                        servings = servings)
  ingredients_df <- tibble(recipe_name = title, ingredient = ingredients,
                           quantity = ingredients_quantity)
  comments_df <- tibble(recipe_name = title, user = comments_user_name,
                        date = comments_date, text = comments_text)
  keywords_df <- tibble(recipe_name = title, keyword = keywords)
  categories_df <- categories %>%
    flatten_df() %>%
    mutate(recipe_name = title)

  list(recepies_df, ingredients_df, comments_df, categories_df)
}

url <- "https://www.kurashiru.com/recipes/b452b236-c5da-4040-a425-f49f84b391c2"
single_recipe_df <- get_single_recipe_df(url)
glimpse(single_recipe_df) 

