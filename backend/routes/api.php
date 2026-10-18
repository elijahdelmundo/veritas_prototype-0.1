<?php

use App\Http\Controllers\ClinicController;
use App\Http\Middleware\LocalClinicApi;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware(LocalClinicApi::class)->group(function () {
    Route::get('/branches', [ClinicController::class, 'branches']);
    Route::get('/reports', [ClinicController::class, 'reports']);
    Route::put('/branches/{branch}/reports/{date}', [ClinicController::class, 'saveReport']);
    Route::get('/medicine-batches', [ClinicController::class, 'batches']);
    Route::post('/medicine-batches', [ClinicController::class, 'addBatch']);
    Route::patch('/medicine-batches/{batch}', [ClinicController::class, 'updateStock']);
});
