<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MedicineBatch extends Model
{
    protected $fillable = ['branch_id', 'name', 'quantity', 'unit', 'expiry', 'threshold'];

    protected function casts(): array
    {
        return ['quantity' => 'integer', 'threshold' => 'integer', 'expiry' => 'date:Y-m-d'];
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }
}
