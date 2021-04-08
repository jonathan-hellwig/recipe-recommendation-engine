source("web_scraper.R")

path_log_file <- "test.log"
user_name <- "postgres"
password <- ""
last_page <- 875
max_loading_time <- 23

pos_parse_recipe_html <- possibly(parse_recipe_html, otherwise = NULL)

clear_db(user_name, password)
set_up_db(user_name, password)

for (current_page in 1:last_page) {
  recipe_links <- scrape_recipe_links(current_page) 
  recipe_links <- recipe_links[1:2]
  recipes_single_page <- recipe_links %>%
    map(function(link) {
          Sys.sleep(5)
          id <- get_id(link)
          log_info(path_log_file, glue::glue("Obtaining recipe {id}."))
            scrape_dynamic_page_firefox(link, max_loading_time)}) %>%
  map(function(recipe_html) {
        pos_parse_recipe_html(recipe_html)}) %>%
  map2(recipe_links, function(recipe_df, link) {
         id <- get_id(link)
         if (is.null(recipe_df)) {
           log_warn(path_log_file, glue::glue("Failed to parse {id}."))
         } else {
           log_info(path_log_file, glue::glue("Successfully parsed {id}."))
           recipe_df <- recipe_df %>%
             add_id(id)
         }
         recipe_df}) %>%
  discard(~is.null(.x))
  if (length(recipes_single_page) != 0) {
    log_info(path_log_file, "Writing to database.")
    recipes_single_page %>%
      bind_rows_recipe_list() %>%
      write_to_db(user_name, password)
    log_info(path_log_file, "Finished writing to database.")
  } else {
    log_warn(path_log_file, "Failed to write to database.")
  }
}
