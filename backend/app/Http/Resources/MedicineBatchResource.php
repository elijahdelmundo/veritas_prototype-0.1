<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MedicineBatchResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'branch_id' => $this->branch_id,
            'branch' => $this->branch->name,
            'name' => $this->name,
            'quantity' => $this->quantity,
            'unit' => $this->unit,
            'expiry' => $this->expiry->format('Y-m-d'),
            'threshold' => $this->threshold,
        ];
    }
}
