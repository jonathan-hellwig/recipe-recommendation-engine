library(dplyr)

con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                      host = "localhost",
                      port = 5432,
                      dbname = "gregp",
                      user = "postgres",
                      password = "")
copy_to(con, nycflights13::flights, "flights",
  temporary = FALSE,
  indexes = list(
    c("year", "month", "day"),
    "carrier",
    "tailnum",
    "dest"
  )
)

flights_db <- tbl(con, "flights")
flights_db
dtf <- tibble(year = 2020L, month = 1L, day = 1L, dep_time = 5000L, sched_dep_time = 5L, dep_delay = 4.0, arr_time = 500L,
              sched_arr_time = 5L, arr_delay = 11.0, carrier = "GER", flight = 34344L, tailnum = "N44332", origin = "GER",
              dest = "IFH")
DBI::dbWriteTable(con, "flights", dtf, append = TRUE, row.names = FALSE)
flights_db %>%
  filter(year == 2020L)
