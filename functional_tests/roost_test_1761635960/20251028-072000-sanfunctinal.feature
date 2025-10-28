Feature: Comprehensive API Testing Suite

  Background:
    Given the API base URL is set from environment variable 'API_BASE_URL'
    And the authorization header is set from environment variable 'AUTH_TOKEN'
    And the content type is set to 'application/json'
    And the default timeout is set to 30 seconds

  Scenario: User Authentication - Valid Login
    Given a user account exists with username 'testuser@example.com' and password 'ValidPass123!'
    When I send a POST request to '/api/auth/login' with payload:
      """
      {
        "username": "testuser@example.com",
        "password": "ValidPass123!"
      }
      """
    Then the response status should be 200
    And the response should contain a valid JWT token
    And the response should contain 'success': true
    And the response should contain 'userId'
    And the authorization header should be updated with the new token

  Scenario: User Authentication - Invalid Password
    Given a user account exists with username 'testuser@example.com' and password 'ValidPass123!'
    When I send a POST request to '/api/auth/login' with payload:
      """
      {
        "username": "testuser@example.com",
        "password": "WrongPassword123!"
      }
      """
    Then the response status should be 401
    And the response should contain 'error': 'Invalid credentials'
    And the response should contain 'success': false

  Scenario: User Authentication - Non-existent User
    When I send a POST request to '/api/auth/login' with payload:
      """
      {
        "username": "nonexistent@example.com",
        "password": "SomePassword123!"
      }
      """
    Then the response status should be 401
    And the response should contain 'error': 'User not found'

  Scenario: User Authentication - Account Lockout After Multiple Failed Attempts
    Given a user account exists with username 'lockeduser@example.com' and password 'ValidPass123!'
    When I send 5 consecutive POST requests to '/api/auth/login' with payload:
      """
      {
        "username": "lockeduser@example.com",
        "password": "WrongPassword{i}!"
      }
      """
    And the response status should be 401 for each failed attempt
    And the final response should contain 'error': 'Account temporarily locked'
    And the response should indicate lockout duration in seconds

  Scenario: User Authentication - Valid Logout
    Given I have a valid authentication token from previous login
    When I send a POST request to '/api/auth/logout'
    Then the response status should be 200
    And the response should contain 'success': true
    And the token should be invalidated server-side
    And subsequent requests with the old token should return 401

  Scenario: Data Validation - Maximum Length Validation
    When I send a POST request to '/api/users' with payload:
      """
      {
        "username": "averylongusernamethatexceedsthemaximallimitof50characters123456789",
        "email": "test@example.com",
        "password": "ValidPass123!"
      }
      """
    Then the response status should be 400
    And the response should contain validation errors
    And the response should contain 'username': 'Field exceeds maximum length of 50 characters'

  Scenario: Data Validation - Email Format Validation
    When I send a POST request to '/api/users' with payload:
      """
      {
        "username": "testuser",
        "email": "invalid-email-format",
        "password": "ValidPass123!"
      }
      """
    Then the response status should be 400
    And the response should contain validation errors
    And the response should contain 'email': 'Invalid email format'

  Scenario: Data Validation - Special Character Handling
    When I send a POST request to '/api/users' with payload:
      """
      {
        "username": "testuser@#$%",
        "email": "test@example.com",
        "password": "ValidPass123!@#$%^&*()"
      }
      """
    Then the response status should be 200
    And the response should contain 'success': true
    And the created user should properly handle special characters

  Scenario: Data Validation - Required Field Validation
    When I send a POST request to '/api/users' with payload:
      """
      {
        "username": "testuser"
      }
      """
    Then the response status should be 400
    And the response should contain validation errors
    And the response should contain 'email': 'Email is required'
    And the response should contain 'password': 'Password is required'

  Scenario: Data Validation - SQL Injection Attempt
    When I send a POST request to '/api/users' with payload:
      """
      {
        "username": "test'; DROP TABLE users; --",
        "email": "test@example.com",
        "password": "ValidPass123!"
      }
      """
    Then the response status should be 400
    And the response should contain validation errors
    And the response should not execute the malicious SQL command
    And the users table should remain intact

  Scenario: Search Functionality - Exact Match Search
    Given the database contains user records including one with username 'exactmatch'
    When I send a GET request to '/api/users/search' with query parameter 'username=exactmatch'
    Then the response status should be 200
    And the response should contain exactly 1 result
    And the result should have username 'exactmatch'

  Scenario: Search Functionality - Partial Match Search
    Given the database contains user records with usernames 'user1', 'user2', 'user3'
    When I send a GET request to '/api/users/search' with query parameter 'searchTerm=user'
    Then the response status should be 200
    And the response should contain exactly 3 results
    And all results should contain 'user' in their username

  Scenario: Search Functionality - Case Insensitive Search
    Given the database contains user records with usernames 'TestUser', 'TESTUSER', 'testuser'
    When I send a GET request to '/api/users/search' with query parameter 'searchTerm=TESTUSER&caseSensitive=false'
    Then the response status should be 200
    And the response should contain exactly 3 results
    And all results should match the search term case-insensitively

  Scenario: Search Functionality - Special Character Search
    Given the database contains user records with usernames 'user@domain.com', 'user#123', 'user_name'
    When I send a GET request to '/api/users/search' with query parameter 'searchTerm=@&includeSpecial=true'
    Then the response status should be 200
    And the response should contain results that include special characters
    And the results should be properly encoded

  Scenario: Search Functionality - Empty Search Results
    When I send a GET request to '/api/users/search' with query parameter 'searchTerm=nonexistentuser123456'
    Then the response status should be 200
    And the response should contain 0 results
    And the response should contain 'message': 'No results found'

  Scenario: Search Functionality - Pagination
    Given the database contains 25 user records
    When I send a GET request to '/api/users/search' with query parameters 'page=1&limit=10&sortBy=username&order=asc'
    Then the response status should be 200
    And the response should contain exactly 10 results
    And the response should contain pagination metadata with 'totalPages': 3
    And the response should contain 'currentPage': 1

  Scenario: CRUD Operations - Create New Record
    When I send a POST request to '/api/products' with payload:
      """
      {
        "name": "Test Product",
        "description": "A test product for API testing",
        "price": 99.99,
        "category": "electronics",
        "stockQuantity": 100
      }
      """
    Then the response status should be 201
    And the response should contain 'success': true
    And the response should contain 'productId'
    And the created product should be retrievable via GET /api/products/{productId}

  Scenario: CRUD Operations - Read Existing Record
    Given a product with ID 'test-product-123' exists in the database
    When I send a GET request to '/api/products/test-product-123'
    Then the response status should be 200
    And the response should contain 'name': 'Test Product'
    And the response should contain 'price': 99.99
    And the response should contain all expected product fields

  Scenario: CRUD Operations - Update Existing Record
    Given a product with ID 'test-product-123' exists in the database
    When I send a PUT request to '/api/products/test-product-123' with payload:
      """
      {
        "name": "Updated Test Product",
        "description": "Updated description",
        "price": 149.99,
        "stockQuantity": 150
      }
      """
    Then the response status should be 200
    And the response should contain 'success': true
    And the response should contain 'updatedProduct'
    And the updated product should reflect the changes when retrieved

  Scenario: CRUD Operations - Partial Update Record
    Given a product with ID 'test-product-123' exists in the database
    When I send a PATCH request to '/api/products/test-product-123' with payload:
      """
      {
        "price": 79.99
      }
      """
    Then the response status should be 200
    And the response should contain 'success': true
    And only the price should be updated while other fields remain unchanged

  Scenario: CRUD Operations - Delete Record
    Given a product with ID 'test-product-123' exists in the database
    When I send a DELETE request to '/api/products/test-product-123'
    Then the response status should be 200
    And the response should contain 'success': true
    And the product should no longer exist when retrieved via GET
    And the response should contain 'message': 'Product deleted successfully'

  Scenario: CRUD Operations - Delete Non-existent Record
    When I send a DELETE request to '/api/products/non-existent-product-123'
    Then the response status should be 404
    And the response should contain 'error': 'Product not found'

  Scenario: CRUD Operations - Concurrent Update Handling
    Given a product with ID 'test-product-123' exists in the database
    And I have the current ETag value 'etag-123'
    When I send a PUT request to '/api/products/test-product-123' with payload:
      """
      {
        "name": "Concurrent Update Test",
        "price": 199.99
      }
      """
    And the request header 'If-Match' is set to 'etag-123'
    Then the response status should be 200
    And the response should contain 'success': true
    And the response should contain a new ETag value

  Scenario: Error Handling - Network Timeout
    Given the API endpoint '/api/slow-response' is configured to delay response by 60 seconds
    When I send a GET request to '/api/slow-response'
    Then the request should timeout within 30 seconds
    And the response status should be 408
    And the response should contain 'error': 'Request timeout'

  Scenario: Error Handling - Database Connection Error
    Given the database connection is intentionally disabled
    When I send a POST request to '/api/users' with payload:
      """
      {
        "username": "testuser",
        "email": "test@example.com",
        "password": "ValidPass123!"
      }
      """
    Then the response status should be 500
    And the response should contain 'error': 'Database connection failed'
    And the error should be logged appropriately

  Scenario: Error Handling - Invalid User Permissions
    Given I have a standard user account with limited permissions
    When I send a POST request to '/api/admin/users' with payload:
      """
      {
        "username": "newadmin",
        "email": "admin@example.com"
      }
      """
    Then the response status should be 403
    And the response should contain 'error': 'Insufficient permissions'
    And the response should indicate required permissions

  Scenario: Error Handling - Service Unavailable
    Given the authentication service is intentionally down
    When I send a POST request to '/api/auth/login' with payload:
      """
      {
        "username": "test@example.com",
        "password": "ValidPass123!"
      }
      """
    Then the response status should be 503
    And the response should contain 'error': 'Service temporarily unavailable'
    And the response should contain retry information

  Scenario: Security Testing - SQL Injection Prevention
    When I send a GET request to '/api/users/search' with malicious query parameter 'username=admin\' OR \'1\'=\'1'
    Then the response status should be 200
    And the response should properly escape the input
    And no unauthorized data should be returned
    And the malicious SQL should not be executed

  Scenario: Security Testing - XSS Prevention in Search
    When I send a POST request to '/api/users/search' with payload:
      """
      {
        "searchTerm": "<script>alert('XSS')</script>",
        "includeHTML": false
      }
      """
    Then the response status should be 200
    And the response should properly escape HTML entities
    And the script tag should not be executable

  Scenario: Security Testing - CSRF Protection
    Given I have a valid session token
    When I send a POST request to '/api/users' with payload:
      """
      {
        "username": "testuser",
        "email": "test@example.com"
      }
      """
    And the request does not include a valid CSRF token
    Then the response status should be 403
    And the response should contain 'error': 'CSRF token missing or invalid'

  Scenario: Security Testing - Authorization Bypass Attempt
    Given I have access to user resource with ID 'user123'
    When I send a GET request to '/api/users/user456' (another user's resource)
    Then the response status should be 403
    And the response should contain 'error': 'Access denied'
    And no cross-user data should be accessible

  Scenario: Security Testing - Rate Limiting
    When I send 100 GET requests to '/api/auth/login' within 1 minute with payloads:
      """
      {
        "username": "test@example.com",
        "password": "WrongPassword{i}!"
      }
      """
    Then after 60 requests the response status should be 429
    And the response should contain 'error': 'Rate limit exceeded'
    And the response should indicate retry-after time

  Scenario: Performance Testing - Baseline Performance
    When I send a GET request to '/api/users'
    Then the response should be received within 2000 milliseconds
    And the response status should be 200
    And the response time should be logged for baseline comparison

  Scenario: Performance Testing - Concurrent User Load
    Given I simulate 50 concurrent users
    When each user sends a GET request to '/api/users'
    Then all requests should complete within 5000 milliseconds
    And the response status should be 200 for at least 95% of requests
    And the system should maintain acceptable performance under load

  Scenario: Performance Testing - Stress Test Peak Load
    Given I simulate 200 concurrent users
    When each user performs multiple operations (GET, POST, PUT, DELETE)
    Then the system should handle the load gracefully
    And response times should not exceed 10000 milliseconds
    And error rate should be less than 5%
    And system resources (CPU, memory) should be monitored

  Scenario: Error Handling - Graceful Degradation
    Given the caching service is unavailable
    When I send a GET request to '/api/users/1'
    Then the response status should be 200
    And the response should be served from the database
    And the response should contain 'source': 'database' indicating fallback
    And the response time may be higher but should still be acceptable

  Scenario: Error Handling - Input Sanitization
    When I send a POST request to '/api/users' with payload containing HTML:
      """
      {
        "username": "<b>testuser</b>",
        "email": "test@example.com",
        "description": "<script>alert('test')</script>A normal description"
      }
      """
    Then the response status should be 200
    And the HTML tags should be properly sanitized in the stored data
    And the response should contain the sanitized data
    And no script execution should be possible

  Scenario: Data Validation - Boundary Testing for Numeric Fields
    When I send a POST request to '/api/products' with payload:
      """
      {
        "name": "Boundary Test Product",
        "price": -0.01,
        "stockQuantity": -1
      }
      """
    Then the response status should be 400
    And the response should contain validation errors for negative values
    And the response should indicate minimum allowed values

  Scenario: Search Functionality - Sorting Verification
    Given the database contains products with prices 10, 50, 25, 100
    When I send a GET request to '/api/products/search' with query parameters 'sortBy=price&order=asc'
    Then the response status should be 200
    And the products should be returned in ascending price order
    When I send the same request with 'order=desc'
    Then the products should be returned in descending price order

  Scenario: CRUD Operations - Validation of Business Rules
    When I send a POST request to '/api/orders' with payload that violates business rules:
    """
    {
      "customerId": "customer123",
      "items": [],
      "totalAmount": 100.00
    }
    """
    Then the response status should be 400
    And the response should contain 'error': 'Order must contain at least one item'
    And the business rule validation should be enforced

  Scenario: Authentication - Session Timeout Handling
    Given I have an authentication token that expires in 1 minute
    And I wait for 61 seconds
    When I send a GET request to '/api/users/profile'
    Then the response status should be 401
    And the response should contain 'error': 'Session expired'
    And the response should indicate token renewal process
