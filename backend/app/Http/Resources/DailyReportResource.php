<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DailyReportResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'branch_id' => $this->branch_id,
            'branch' => $this->branch->name,
            'date' => $this->date->format('Y-m-d'),
            'patients' => $this->patients,
            'revenue' => $this->revenue,
            'expenses' => $this->expenses,
            'notes' => $this->notes ?? '',
        ];
    }
}
