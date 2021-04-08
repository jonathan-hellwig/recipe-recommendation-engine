library(testthat)
source("../scripts/web_scraper.R")

test_that("bind_rows_recipe_list returns empty tibble", {
  expected_result <- list(recipes = tibble(id = character(),
                                 recipe_name = character(),
                                 cooking_time = character(),
                                 servings = character(),
                                 instructions = character()),
                ingredients = tibble(id = character(),
                                     ingredient = character(),
                                     quantity = character()),
                comments = tibble(id = character(),
                                  user = character(),
                                  date = character(), text = character()),
                categories = tibble(id = character(), X1 = character(),
                                    X2 = character(), X3 = character(),
                                    X4 = character(), X5 = character()))
  expect_equal(bind_rows_recipe_list(list()), expected_result)
})

test_that("bind_rows_recipe_list is invarient for a single recipe", {
  parsed_recipe <- read_html("test.html", encoding = "utf-8") %>%
    parse_recipe_html()
  expect_equal(bind_rows_recipe_list(list(parsed_recipe)), parsed_recipe)
})
test_that("parse_recipe_html works", {
  parsed_recipe <- read_html("test.html", encoding = "utf-8") %>%
    parse_recipe_html()

})
test_that("write_to_db", {
  user_name <- "postgres"
  password <- ""
  input <- list(recipes = tibble(id = character(),
                                 recipe_name = character(),
                                 cooking_time = character(),
                                 servings = character(),
                                 instructions = character()),
                ingredients = tibble(id = character(),
                                     ingredient = character(),
                                     quantity = character()),
                comments = tibble(id = character(),
                                  user = character(),
                                  date = character(), text = character()),
                categories = tibble(id = character(), X1 = character(),
                                    X2 = character(), X3 = character(),
                                    X4 = character(), X5 = character()))
  write_to_db(input, user_name, password)
})

