# code works with Selenium 4.x.

import pytest
import allure
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

baseUrl = 'https://reghinaa.github.io/json-files/finaljson/processed/allmissions.html'

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
@allure.feature("Main 'High-Energy Missions' page BOTTOM links verification test")
@allure.story("Verifying that 'Current Missions' link is working")
@allure.severity(allure.severity_level.MINOR)

def test_current_missions_link(env_setup):
    driver = env_setup

    with allure.step("Open main 'High-Energy Missions' page with links"):
        driver.get(baseUrl)

    with allure.step("Click on 'Current Missions' link"):
        driver.find_element(By.LINK_TEXT, "Current Missions").click()
        WebDriverWait(driver, 10).until(
            EC.title_contains("Current Missions")
        )  # Подождать загрузку

    with allure.step("Verify 'Current Missions' page title"):
        assert driver.title == "Current Missions", "❌ 'Current Missions' link and expected 'Current Missions' page was not found"