from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import sys

def set_up():
    options = Options()
    options.headless = False
    options.add_argument("--connect-existing") 
    options.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36"

    firefox_profile = webdriver.FirefoxProfile('/home/cmp/.mozilla/firefox/6zf2bg26.scraping')
    driver = webdriver.Firefox(options = options, firefox_profile = firefox_profile)
    return driver

def print_page_source(driver, url):
    driver.get(url)
    print(driver.page_source)
    #driver.quit()

driver = set_up()
url = sys.argv[1]
print_page_source(driver, url)
