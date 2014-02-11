Feature: Admin user interface
  As a site admin
  So that I can have a commanding view of important information
  I want a specialized interface

  Background:
    Given the following users are registered:
      | email                 | password       | admin | confirmed_at        | organization | pending_organization |
      | admin@harrowcn.org.uk | mypassword1234 | true  | 2008-01-01 00:00:00 |              |                      |
    And I am signed in as a admin
    And I am on the home page

  Scenario Outline: Top navbar has organization dropdown menus

    Then the organization menu has a dropdown menu with a <link> link
  Examples:
    | link                 |
    | All                  |
    | Without Users        |
    | With Generated Users |