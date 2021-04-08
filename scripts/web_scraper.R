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
    output <- f(...)
    log4r::info(default_logger, stopping_message)
    return(output)
  }
}

scrape_recipe_links <- function(page_number) {
  recipe_links <- vector(mode = "character")
  base_url <- glue::glue("https://www.kurashiru.com/video_categories/139?page={page_number}")
  recipe_links <- rvest::read_html(base_url) %>%
    html_nodes(".title") %>%
    html_attr("href")
  recipe_links %>%
    map_chr(~glue("https://www.kurashiru.com", .x))
}

scrape_recipes <- function(recipe_links, path_log_file) {
    scrape_dynamic_page_delayed <- scrape_dynamic_page_firefox %>%
      delay_by(5)
    recipe_links %>%
      purrr::map2(1:length(recipe_links), function(url, recipe_number) {
                  scrape_page <- log_message(scrape_dynamic_page_delayed,
                      path_log_file,
                      glue::glue("Starting to obtain recipe {recipe_number}."),
                      glue::glue("Finished obtaining recipe {recipe_number}."))
				          scrape_page(url) %>%
                    parse_recipe_html() %>%
                    add_id(get_id(url))
  })
}
log_info <- function(file_path, info_message) {
  info_logger<- log4r::logger(appenders = log4r::file_appender(file_path))
  log4r::info(info_logger, info_message)
}
log_warn <- function(file_path, warning_message) {
  warn_logger <- log4r::logger(appenders = log4r::file_appender(file_path))
  log4r::warn(warn_logger, warning_message)
  return()
}
log_error <- function(file_path, error_message) {
  error_logger <- log4r::logger(appenders = log4r::file_appender(file_path))
  log4r::error(error_logger, error_message)
}
bind_rows_recipe_list <- function(recipe_list) {
  recipe_list %>%
    reduce(function(first_list, second_list) {
             purrr::map2(first_list, second_list, dplyr::bind_rows)})
}
                                 
scrape_dynamic_page_chrome  <- function(url, chrome_client_name, max_duration) {
  tmp <- tempfile(fileext = ".html")
  status <- glue::glue("{chrome_client_name} --log-level=3 --headless --disable-gpu --dump-dom {url} > {tmp}") %>%
    system(timeout = max_duratoin)
  if (status == 0) {
    recipe_html <- rvest::read_html(tmp, encoding = "utf-8")
  } else {
    recipe_html <- NULL
  }
  file.remove(tmp)
  recipe_html
}

scrape_dynamic_page_firefox <- function(url, max_duration) {
  tmp <- tempfile(fileext = ".html")
  status <- glue::glue("python3 scrape_page.py {url} > {tmp}") %>%
    system(timeout = max_duration)
  if (status == 0) {
    recipe_html <- rvest::read_html(tmp, encoding = "utf-8")
  } else {
    recipe_html <- NULL
  }
  file.remove(tmp)
  recipe_html
}

parse_recipe_html <- function(content) {
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
  recepies_df <- tibble(recipe_name = title, cooking_time = cooking_time,
                        servings = servings, instructions = instructions)
  ingredients_df <- tibble(ingredient = ingredients,
                           quantity = ingredients_quantity)
  comments_df <- tibble(user = comments_user_name,
                        date = comments_date, text = comments_text)
  keywords_df <- tibble(keyword = keywords)
  categories_df <- categories %>%
    flatten_df() 
  list(recipes = recepies_df, ingredients = ingredients_df,
       comments = comments_df, categories = categories_df)
}

get_id <- function(url) {
  stringr::str_sub(url, start = 35L, end = -1L)
}

add_id <- function(df_list, id) {
  df_list %>%
    purrr::map(function(df) {
                 df %>%
                  mutate(df, id = id) %>%
                  select(id, everything())})
}

write_to_db <- function(dataframes, user_name, password) {
  con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                        host = "localhost",
                        port = 5432,
                        dbname = "recipes",
                        user = user_name,
                        password = password)
  table_names <- names(dataframes)
  write_status <- purrr::map2_lgl(dataframes, table_names,
    ~DBI::dbWriteTable(con, .y, .x, append = TRUE, row.names = FALSE))
  DBI::dbDisconnect(con)
  return(write_status)
}

clear_db <- function(user_name, password) {
  con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                        host = "localhost",
                        port = 5432,
                        dbname = "recipes",
                        user = user_name,
                        password = password)
  status <- DBI::dbListTables(con) %>%
    map_lgl(~DBI::dbRemoveTable(con, .x))
  DBI::dbDisconnect(con)
  return(status)
}

set_up_db <- function(user_name, password) {
  con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                        host = "localhost",
                        port = 5432,
                        dbname = "recipes",
                        user = user_name,
                        password = password)
  fields <- c(id = "text", X1 = "text", X2 = "text", X3 = "text",
              X4 = "text", X5 = "text")
  status <- DBI::dbCreateTable(con, "categories", fields)
  DBI::dbDisconnect(con)
  return(status)
}

url <- "https://www.kurashiru.com/recipes/3365e1c3-f4e5-4de4-8b04-f1ad19e44f51"
#output <- get_single_dynamic_recipe_df(url)
#print(output)
#write_to_db(output)
#get_recipes_in_page_range(1, 1)
