<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DailyReport extends Model
{
    protected $fillable = ['branch_id', 'date', 'patients', 'revenue', 'expenses', 'notes'];

    protected function casts(): array
    {
        return ['date' => 'date:Y-m-d', 'patients' => 'integer', 'revenue' => 'decimal:2', 'expenses' => 'decimal:2'];
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }
}
