'use client'

import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import MagicalBackground from '@/components/ui/MagicalBackground'
import MagicalCard from '@/components/ui/MagicalCard'
import MagicalInput from '@/components/ui/MagicalInput'
import MagicalDropdown from '@/components/ui/MagicalDropdown'
import MagicalButton from '@/components/ui/MagicalButton'
import { createClient } from '@/lib/supabase/client'

const houseOptions = [
  { value: 'gryffindor', label: 'Gryffindor', icon: '🦁' },
  { value: 'hufflepuff', label: 'Hufflepuff', icon: '🦡' },
  { value: 'ravenclaw', label: 'Ravenclaw', icon: '🦅' },
  { value: 'slytherin', label: 'Slytherin', icon: '🐍' }
]

export default function LoginPage() {
  const router = useRouter()
  const [magicalName, setMagicalName] = useState('')
  const [password, setPassword] = useState('')
  const [house, setHouse] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const supabase = createClient()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    setLoading(true)

    try {
      // Derive email from magical name (sanitize to match registration)
      const sanitizedMagicalName = magicalName.toLowerCase().replace(/\s+/g, '').replace(/[^a-z0-9]/g, '')
      const email = `${sanitizedMagicalName}@gmail.com`
      
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (signInError) {
        console.error('[LOGIN] Sign-in rejected:', signInError)
        setError('The ancient records could not verify your identity.')
        setLoading(false)
        return
      }

      router.replace('/home')
    } catch {
      setError('A magical disturbance occurred. Please try again.')
      setLoading(false)
    }
  }

  return (
    <MagicalBackground>
      <div className="min-h-screen flex items-center justify-center p-4 overflow-visible">
        <MagicalCard className="w-full max-w-md" overflow="visible">
          <div className="text-center mb-8">
            <div className="text-5xl mb-4">🧹</div>
            <h1 className="text-3xl font-bold bg-gradient-to-r from-amber-400 to-amber-600 bg-clip-text text-transparent mb-2">
              Enter the Academy
            </h1>
            <p className="text-slate-400">Welcome back, young wizard</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-6">
            <MagicalInput
              type="text"
              placeholder="Magical Name"
              value={magicalName}
              onChange={(e) => setMagicalName(e.target.value)}
              required
            />

            <MagicalInput
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />

            <MagicalDropdown
              options={houseOptions}
              value={house}
              onChange={setHouse}
              placeholder="Select Your House"
              error={error && !house ? 'House is required' : ''}
            />

            {error && (
              <div className="bg-rose-600/20 border border-rose-500/50 rounded-lg p-3 text-rose-400 text-sm">
                {error}
              </div>
            )}

            <MagicalButton
              type="submit"
              disabled={loading}
              className="w-full"
            >
              {loading ? 'Entering...' : 'Enter the Academy'}
            </MagicalButton>
          </form>

          <div className="mt-6 text-center space-y-2">
            <button
              onClick={() => router.push('/forgot-password')}
              className="text-slate-400 hover:text-amber-400 text-sm"
            >
              Forgot Password?
            </button>
            <p className="text-slate-400">
              New to the wizarding world?{' '}
              <button
                onClick={() => router.push('/register')}
                className="text-amber-400 hover:text-amber-300 font-semibold"
              >
                Create Magical Account
              </button>
            </p>
          </div>
        </MagicalCard>
      </div>
    </MagicalBackground>
  )
}
