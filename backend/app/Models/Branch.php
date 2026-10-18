<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Branch extends Model
{
    protected $fillable = ['name', 'address', 'target', 'growth', 'staff'];

    protected function casts(): array
    {
        return ['staff' => 'array', 'target' => 'integer', 'growth' => 'float'];
    }
}
