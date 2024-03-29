<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GroupOwner extends Model
{
    use HasFactory;

    protected $table = 'group_owner';
    public $timestamps = false;

    protected $fillable = [
        'group_id',
        'user_id'
    ];
}
