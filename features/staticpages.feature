Feature: I want to have a contact and about us link in all the app pages
  As the system owner
  So that I can be contacted
  I want to show a contact page and an about us page
  Tracker story ID: https://www.pivotaltracker.com/story/show/45693625

Background: organizations have been added to database
  Given the following organizations exist:
    | name             | address        |
    | Friendly Charity | 83 pinner road |
  Given the following pages exist:
    | name         | permalink  | content                                                   |
    | 404          | 404        | We're sorry, but we couldn't find the page you requested! |
    | About Us     | about      | abc123                                                    |
    | Contact Info | contact    | def456                                                    |

  Scenario Outline: the about us page is accessible on all pages
    Given I am on the <page>
    When I follow "About Us"
    Then I should see "abc123"
  Examples:
    | page                                |
    | home page                           |
    | charity search page                 |
    | new charity page                    |
    | charity page for "Friendly Charity" |

  Scenario Outline: the contact page is accessible on all pages
    Given I am on the <page>
    When I follow "Contact"
    Then I should see "def456"
  Examples:
    | page                                |
    | home page                           |
    | charity search page                 |
    | new charity page                    |
    | charity page for "Friendly Charity" |