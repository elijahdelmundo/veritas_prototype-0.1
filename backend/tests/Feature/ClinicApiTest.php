<?php

namespace Tests\Feature;

use App\Models\Branch;
use App\Models\DailyReport;
use App\Models\MedicineBatch;
use Database\Seeders\ClinicDemoSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ClinicApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ClinicDemoSeeder::class);
    }

    public function test_lists_persisted_clinic_data(): void
    {
        $this->getJson('/api/v1/branches')->assertOk()->assertJsonCount(6, 'data')
            ->assertJsonPath('data.0.name', 'Laguna');
        $this->getJson('/api/v1/reports')->assertOk()->assertJsonCount(180, 'data')
            ->assertJsonStructure(['data' => [['id', 'branch_id', 'branch', 'date', 'patients', 'revenue', 'expenses', 'notes']]]);
        $this->getJson('/api/v1/medicine-batches')->assertOk()->assertJsonCount(36, 'data');
    }

    public function test_report_put_is_persistent_and_does_not_duplicate_a_branch_date(): void
    {
        $branch = Branch::where('name', 'Pasig')->firstOrFail();
        $date = now('Asia/Manila')->toDateString();
        $url = "/api/v1/branches/{$branch->id}/reports/{$date}";
        $data = ['patients' => 50, 'revenue' => 1234.56, 'expenses' => 120.25, 'notes' => 'Reviewed'];
        $this->putJson($url, $data)->assertOk()->assertJsonPath('data.revenue', '1234.56');
        $this->putJson($url, array_merge($data, ['patients' => 60]))->assertOk();
        $this->assertDatabaseHas('daily_reports', ['branch_id' => $branch->id, 'date' => $date, 'patients' => 60]);
        $this->assertDatabaseCount('daily_reports', 180);
        $this->getJson('/api/v1/reports')->assertJsonFragment(['patients' => 60, 'notes' => 'Reviewed']);
    }

    public function test_invalid_reports_and_unknown_branches_are_rejected(): void
    {
        $id = Branch::firstOrFail()->id;
        $date = now('Asia/Manila')->toDateString();
        $this->putJson("/api/v1/branches/{$id}/reports/{$date}", [
            'patients' => -1, 'revenue' => -2, 'expenses' => 'bad', 'notes' => '',
        ])->assertUnprocessable()->assertJsonValidationErrors(['patients', 'revenue', 'expenses']);
        $future = now('Asia/Manila')->addDay()->toDateString();
        $this->putJson("/api/v1/branches/{$id}/reports/{$future}", [])->assertUnprocessable();
        $this->putJson("/api/v1/branches/999999/reports/{$date}", [])->assertNotFound();
        $this->assertDatabaseCount('daily_reports', 180);
    }

    public function test_batch_creation_and_stock_changes_round_trip_through_database(): void
    {
        $data = ['branch_id' => Branch::firstOrFail()->id, 'name' => 'API test medicine',
            'quantity' => 5, 'unit' => 'vials',
            'expiry' => now('Asia/Manila')->addDays(10)->toDateString(), 'threshold' => 10];
        $created = $this->postJson('/api/v1/medicine-batches', $data)
            ->assertCreated()->assertJsonPath('data.quantity', 5);
        $id = $created->json('data.id');
        $url = "/api/v1/medicine-batches/{$id}";
        $this->patchJson($url, ['operation' => 'restock', 'quantity' => 7])
            ->assertOk()->assertJsonPath('data.quantity', 12);
        $this->patchJson($url, ['operation' => 'restock', 'quantity' => 3])
            ->assertOk()->assertJsonPath('data.quantity', 15);
        $this->patchJson($url, ['operation' => 'set', 'quantity' => 0])
            ->assertOk()->assertJsonPath('data.quantity', 0);
        $this->assertDatabaseHas('medicine_batches', ['id' => $id, 'quantity' => 0, 'expiry' => $data['expiry']]);
        $this->getJson('/api/v1/medicine-batches')->assertJsonFragment(['name' => 'API test medicine', 'quantity' => 0]);
    }

    public function test_invalid_batches_and_stock_changes_do_not_mutate_data(): void
    {
        $this->postJson('/api/v1/medicine-batches', [
            'branch_id' => 999999, 'name' => ' ', 'quantity' => -1, 'unit' => 'invalid',
            'expiry' => now('Asia/Manila')->subDay()->toDateString(), 'threshold' => -1,
        ])->assertUnprocessable()->assertJsonValidationErrors(['branch_id', 'name', 'quantity', 'unit', 'expiry', 'threshold']);
        $batch = MedicineBatch::firstOrFail();
        foreach ([['operation' => 'restock', 'quantity' => 0],
            ['operation' => 'set', 'quantity' => -1], ['operation' => 'invalid', 'quantity' => 3]] as $payload) {
            $this->patchJson("/api/v1/medicine-batches/{$batch->id}", $payload)->assertUnprocessable();
        }
        $this->assertDatabaseHas('medicine_batches', ['id' => $batch->id, 'quantity' => $batch->quantity]);
        $this->assertDatabaseCount('medicine_batches', 36);
        $this->patchJson('/api/v1/medicine-batches/999999', ['operation' => 'set', 'quantity' => 2])->assertNotFound();
    }

    public function test_demo_seeder_preserves_existing_edits(): void
    {
        $report = DailyReport::firstOrFail();
        $report->update(['notes' => 'Keep my edit']);
        $batch = MedicineBatch::firstOrFail();
        $batch->update(['quantity' => 999]);
        $this->seed(ClinicDemoSeeder::class);
        $this->assertSame('Keep my edit', $report->fresh()->notes);
        $this->assertSame(999, $batch->fresh()->quantity);
        $this->assertDatabaseCount('medicine_batches', 36);
        $this->assertDatabaseCount('daily_reports', 180);
    }

    public function test_cors_allows_local_flutter_and_rejects_other_origins(): void
    {
        $this->options('/api/v1/reports', [], [
            'Origin' => 'http://localhost:54321', 'Access-Control-Request-Method' => 'GET',
        ])->assertNoContent()->assertHeader('Access-Control-Allow-Origin', 'http://localhost:54321');
        $response = $this->options('/api/v1/reports', [], [
            'Origin' => 'https://unrelated.example', 'Access-Control-Request-Method' => 'GET',
        ]);
        $this->assertFalse($response->headers->has('Access-Control-Allow-Origin'));
    }

    public function test_prototype_api_is_unavailable_in_production(): void
    {
        $this->app['env'] = 'production';
        $this->getJson('/api/v1/branches')->assertStatus(503);
    }
}
