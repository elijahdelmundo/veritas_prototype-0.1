<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('branches', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('address');
            $table->unsignedInteger('target');
            $table->decimal('growth', 6, 2);
            $table->json('staff');
            $table->timestamps();
        });
        Schema::create('daily_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('branch_id')->constrained()->restrictOnDelete();
            $table->date('date');
            $table->unsignedInteger('patients');
            $table->decimal('revenue', 14, 2);
            $table->decimal('expenses', 14, 2);
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->unique(['branch_id', 'date']);
        });
        Schema::create('medicine_batches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('branch_id')->constrained()->restrictOnDelete();
            $table->string('name');
            $table->unsignedInteger('quantity');
            $table->string('unit');
            $table->date('expiry');
            $table->unsignedInteger('threshold');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('medicine_batches');
        Schema::dropIfExists('daily_reports');
        Schema::dropIfExists('branches');
    }
};
