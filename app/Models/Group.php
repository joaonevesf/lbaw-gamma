<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Group extends Model
{
    use HasFactory;

    protected $hidden = [
        'tsvectors'
    ];

    /**
     *   Get posts of a group
     *
     * @return Array with the posts of a group
     */
    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }
}