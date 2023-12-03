<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\FriendRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class FriendController extends Controller
{
    public function show_friends(Request $request, string $username)
    {
        $user = User::where('username', $username)->firstOrFail();

        $friends = $user->friends()->get();

        return view('pages.friends', [
            'user' => $user,
            'friends' => $friends,
            'tab' => 'friends'
        ]);
    }

    public function show_friend_requests(string $username)
    {
        $user = User::where('username', $username)->firstOrFail();

        if ($user->id != Auth::id()) {
            abort(403);
        }

        $friendRequests = $user->received_pending_friend_requests()->get();

        return view('pages.friends', ['user' => $user, 'friendRequests' => $friendRequests, 'tab' => 'requests']);
    }

    public function add_friend_request(Request $request, string $username)
    {
        $user = User::where('username', $username)->firstOrFail();

        if (!$request->user()->is_friend($user)) {
            FriendRequest::create([
                'user_id' => Auth::id(),
                'friend_id' => $user->id
            ]);
        } else {
            return response()->json([
                'message' => 'Friend request already sent.'
            ], 400);
        }

        return response()->json([
            'message' => 'Friend request sent.'
        ], 200);
    }

    public function remove_friend(Request $request, string $username)
    {
        $user = User::where('username', $username)->firstOrFail();

        if ($request->user()->is_friend($user)) {
            DB::table('friends')
                ->where('friend1', '=', Auth::id())
                ->where('friend2', '=', $user->id)
                ->orWhere('friend1', '=', $user->id)
                ->where('friend2', '=', Auth::id())
                ->delete();
        }
    }

    public function remove_friend_request($username)
    {
        $user = User::where('username', $username)->firstOrFail();
        $friendRequest = FriendRequest::where('user_id', Auth::id())
            ->where('friend_id', $user->id)
            ->first();

        if ($friendRequest == null) {
            return response()->json([
                'message' => 'Friend request does not exist.'
            ], 404);
        }

        $friendRequest->delete();

        return response()->json([
            'message' => 'Friend request removed.'
        ], 200);
    }

    public function accept_friend_request($username)
    {
        $user = User::where('username', $username)->firstOrFail();
        FriendRequest::where('user_id', $user->id)
            ->where('friend_id', Auth::id())
            ->update(['is_accepted' => true]);

        return response()->json([
            'message' => 'Friend request accepted.'
        ], 200);
    }

    public function decline_friend_request($username)
    {
        $user = User::where('username', $username)->firstOrFail();
        FriendRequest::where('user_id', $user->id)
            ->where('friend_id', Auth::id())
            ->update(['is_accepted' => false]);

        return response()->json([
            'message' => 'Friend request declined.'
        ], 200);
    }

}
