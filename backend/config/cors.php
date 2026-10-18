<?php

return [
    'paths' => ['api/*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'OPTIONS'],
    'allowed_origins' => [],
    'allowed_origins_patterns' => ['#^https?://(localhost|127\\.0\\.0\\.1)(:\\d+)?$#'],
    'allowed_headers' => ['Accept', 'Content-Type'],
    'exposed_headers' => [],
    'max_age' => 600,
    'supports_credentials' => false,
];
