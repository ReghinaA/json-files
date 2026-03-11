# code works with Selenium 4.x.

import pytest
import allure
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

baseUrl = 'https://reghinaa.github.io/json-files/finaljson/processed/agile.html'

@pytest.fixture()
def env_setup():

    # Указываем путь к chromedriver (если в PATH, можно просто Service("chromedriver"))
    service = Service()

    # Инициализация драйвера
    driver = webdriver.Chrome(service=service)
    # Wait 10 seconds till the website will open
    driver.implicitly_wait(10)
    # maximize browser window to full screen
    driver.maximize_window()
    yield driver   # return driver to test

    # when test is done, close ALL windows of the browser
    driver.quit()

# Allure
@allure.feature("AGILE Page links verification test")
@allure.story("Verifying that AstroSat link is working")
@allure.severity(allure.severity_level.CRITICAL)

def test_astrosat_link(env_setup):
    driver = env_setup

    with allure.step("Open 'AGILE' page with links"):
        driver.get(baseUrl)

    with allure.step("Click on 'AstroSat' link"):
        driver.find_element(By.LINK_TEXT, "AstroSat").click()
        WebDriverWait(driver, 10).until(
            EC.title_contains("AstroSat")
        )  # Подождать загрузку

    with allure.step("Verify 'AstroSat' page title"):
        assert driver.title == "AstroSat", "❌ 'AstroSat' link and expected 'AstroSat' page was not found"