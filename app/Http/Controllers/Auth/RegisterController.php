<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;


use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

use Illuminate\View\View;

use App\Models\User;
use Illuminate\Auth\Events\Registered;

class RegisterController extends Controller
{
    /**
     * Display a login form.
     */
    public function showRegistrationForm()
    {
        if (Auth::check()) {
            return redirect('/feed');
        } else {
            return view('auth.register');
        }
    }


    /**
     * Register a new user.
     */
    public function register(Request $request)
    {
        $request->validate([
            'username' => 'required|string|max:250|unique:users',
            'email' => 'required|email|max:250|unique:users',
            'password' => 'required|min:8|confirmed',
            'academic_status' => 'required|string|max:250',
            'university' => 'required|string|max:250',
            'description' => 'nullable|string|max:512',
            'display_name' => 'required|string|max:32',
            'is_private' => 'required',
        ]);

        $last_id = DB::select('SELECT id FROM users ORDER BY id DESC LIMIT 1')[0]->id;
        $new_id = $last_id + 1;

        $user = User::create([
            'id' => $new_id,
            'username' => $request->username,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'academic_status' => $request->academic_status,
            'university' => $request->university == 'None' ? null : $request->university,
            'description' => $request->description,
            'display_name' => $request->display_name,
            'is_private' => ($request->is_private == 'yes'),
            'role' => 2
        ]);


        $credentials = $request->only('email', 'password');

        if (Auth::user() !== null && Auth::user()->is_admin()) {
            return redirect()->route('admin_create_user')
                ->withSuccess('User created with success');
        }


        Auth::attempt($credentials);
        $request->session()->regenerate();


        return redirect('/feed');
    }
}
