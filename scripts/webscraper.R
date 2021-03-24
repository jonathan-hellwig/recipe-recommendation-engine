library(rvest)
library(glue)
library(purrr)
library(tibble)
library(polite)
library(dplyr)

get_content <- function(url) {
  session <- polite::bow(url)
  polite::scrape(session)
}

get_single_recipe_df <- function(session, url) {

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

# Iterate over ever recipe

get_all_recipe_links <- function(session, max_number_pages) {
  recipe_links <- vector(mode = "character")
  for (current_page in 1:max_number_pages) {
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
base_url <- "https://www.kurashiru.com/video_categories/139"
session <- polite::bow(base_url)
recipe_links <- get_all_recipe_links(session, 1)
safe_get_single_recipe_df <- safely(get_single_recipe_df)
combined_recipes <- map(recipe_links, ~safe_get_single_recipe_df(session, .x))
combined_recipes %>%
  map("error") %>%
  purrr::discard(~is.null(.))
combined_recipes_df <- combined_recipes %>%
  map("result") %>%
  reduce(function(first_list, second_list) {
           map2(first_list, second_list, bind_rows)})
