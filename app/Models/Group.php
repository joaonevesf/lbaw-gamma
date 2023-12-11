<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use App\Http\Controllers\FileController;

use App\Models\GroupRequest;
class Group extends Model
{
    use HasFactory;

    protected $fillable = [
        'id',
        'name',
        'description',
        'is_private',
        'tsvectors',
        'image'
    ];

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class, "group_id");
    }

    public function requests(): HasMany
    {
        return $this->hasMany(GroupRequest::class, 'group_id');
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'group_user', 'group_id', 'user_id');
    }

    public function getProfileImage()
    {
        return FileController::get('groupProfile', $this->id);
    }
}
