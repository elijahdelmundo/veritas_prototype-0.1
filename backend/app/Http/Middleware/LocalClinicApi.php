<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class LocalClinicApi
{
    public function handle(Request $request, Closure $next): Response
    {
        // Authentication and branch policies must be implemented before public use.
        if (! app()->environment(['local', 'testing'])) {
            return response()->json(['message' => 'The clinic prototype API is only available in local development.'], 503);
        }

        return $next($request);
    }
}
