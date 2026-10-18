<?php

namespace Database\Seeders;

use App\Models\Branch;
use App\Models\DailyReport;
use App\Models\MedicineBatch;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ClinicDemoSeeder extends Seeder
{
    public function run(): void
    {
        $branches = json_decode(file_get_contents(__DIR__.'/data/clinic_demo.json'), true, flags: JSON_THROW_ON_ERROR);
        $today = now('Asia/Manila')->startOfDay();
        $names = ['Lidocaine 2%', 'Paracetamol 500 mg', 'Amoxicillin 500 mg', 'Ibuprofen 200 mg', 'Cetirizine 10 mg', 'Alcohol 70%'];
        $units = ['vials', 'tablets', 'capsules', 'tablets', 'tablets', 'bottles'];
        DB::transaction(function () use ($branches, $today, $names, $units) {
            foreach ($branches as $b => $data) {
                $branch = Branch::firstOrCreate(['name' => $data['name']], $data);
                for ($day = 29; $day >= 0; $day--) {
                    $patients = 24 + (($b * 11 + (29 - $day) * 7) % 34);
                    DailyReport::firstOrCreate(
                        ['branch_id' => $branch->id, 'date' => $today->copy()->subDays($day)->toDateString()],
                        ['patients' => $patients, 'revenue' => $patients * (720 + $b * 65),
                            'expenses' => $patients * (260 + $b * 23), 'notes' => 'Sample daily operations.']
                    );
                }
                foreach ($names as $m => $name) {
                    // Never reset quantities or expiry when rerunning the demo seeder.
                    MedicineBatch::firstOrCreate(
                        ['branch_id' => $branch->id, 'name' => $name],
                        ['quantity' => $m === 0 && $b % 2 === 0 ? 8 + $b : 65 + $b * 17 + $m * 23,
                            'unit' => $units[$m],
                            'expiry' => $today->copy()->addDays($m === 2 && $b < 2 ? 24 : 160 + $m * 38 + $b * 9)->toDateString(),
                            'threshold' => $m === 0 ? 20 : 40]
                    );
                }
            }
        });
    }
}
