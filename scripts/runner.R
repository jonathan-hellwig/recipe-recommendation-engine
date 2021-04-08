source("web_scraper.R")


last_page <- 1
path_log_file <- "runner.log"
db_user_name <- "postgres"
db_password <- ""
write_to_db_log <- log_message(write_to_db, path_log_file,
                    "Starting to write to database",
                    "Finished writing to database")
for (current_page in 1:last_page) {
  recipes <- scrape_recipe_links(current_page) %>%
    scrape_recipes(path_log_file) %>%
    bind_rows_recipe_list()
  
  write_to_db_log(recipes, db_user_name, db_password)
}
