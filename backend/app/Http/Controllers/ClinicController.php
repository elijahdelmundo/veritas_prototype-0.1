<?php

namespace App\Http\Controllers;

use App\Http\Resources\DailyReportResource;
use App\Http\Resources\MedicineBatchResource;
use App\Models\Branch;
use App\Models\DailyReport;
use App\Models\MedicineBatch;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ClinicController extends Controller
{
    public function branches()
    {
        return response()->json(['data' => Branch::orderBy('id')->get([
            'id', 'name', 'address', 'target', 'growth', 'staff',
        ])]);
    }

    public function reports()
    {
        return DailyReportResource::collection(DailyReport::with('branch')->orderBy('date')->orderBy('branch_id')->get());
    }

    public function saveReport(Request $request, Branch $branch, string $date)
    {
        Validator::make(['date' => $date], [
            'date' => ['required', 'date_format:Y-m-d', 'before_or_equal:'.now('Asia/Manila')->toDateString()],
        ])->validate();
        $data = $request->validate([
            'patients' => ['required', 'integer', 'min:0', 'max:1000000'],
            'revenue' => ['required', 'numeric', 'min:0', 'max:999999999999.99', 'decimal:0,2'],
            'expenses' => ['required', 'numeric', 'min:0', 'max:999999999999.99', 'decimal:0,2'],
            'notes' => ['present', 'nullable', 'string', 'max:5000'],
        ]);
        $report = DailyReport::updateOrCreate(
            ['branch_id' => $branch->id, 'date' => $date],
            $data
        );

        return new DailyReportResource($report->load('branch'));
    }

    public function batches()
    {
        return MedicineBatchResource::collection(MedicineBatch::with('branch')->orderBy('id')->get());
    }

    public function addBatch(Request $request)
    {
        $data = $request->validate([
            'branch_id' => ['required', 'integer', Rule::exists('branches', 'id')],
            'name' => ['required', 'string', 'max:255'],
            'quantity' => ['required', 'integer', 'min:0', 'max:1000000000'],
            'unit' => ['required', Rule::in(['vials', 'tablets', 'capsules', 'bottles', 'boxes'])],
            'expiry' => ['required', 'date_format:Y-m-d', 'after_or_equal:'.now('Asia/Manila')->toDateString()],
            'threshold' => ['required', 'integer', 'min:0', 'max:1000000000'],
        ]);
        $batch = MedicineBatch::create($data);

        return (new MedicineBatchResource($batch->load('branch')))->response()->setStatusCode(201);
    }

    public function updateStock(Request $request, MedicineBatch $batch)
    {
        $data = $request->validate([
            'operation' => ['required', Rule::in(['restock', 'set'])],
            'quantity' => ['required', 'integer', 'min:0', 'max:1000000000'],
        ]);
        if ($data['operation'] === 'restock' && $data['quantity'] < 1) {
            throw ValidationException::withMessages(['quantity' => 'Restock quantity must be greater than zero.']);
        }
        $saved = DB::transaction(function () use ($batch, $data) {
            $current = MedicineBatch::lockForUpdate()->findOrFail($batch->id);
            $quantity = $data['operation'] === 'restock'
                ? $current->quantity + $data['quantity']
                : $data['quantity'];
            if ($quantity > 1000000000) {
                throw ValidationException::withMessages(['quantity' => 'On-hand quantity exceeds the supported limit.']);
            }
            $current->update(['quantity' => $quantity]);

            return $current->load('branch');
        });

        return new MedicineBatchResource($saved);
    }
}
