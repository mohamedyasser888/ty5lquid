'use client'

import React, { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import MagicalBackground from '@/components/ui/MagicalBackground'
import MagicalCard from '@/components/ui/MagicalCard'
import MagicalNavbar from '@/components/ui/MagicalNavbar'
import RoomCard from '@/components/ui/RoomCard'
import LoadingMagic from '@/components/ui/LoadingMagic'
import LoadingSkeleton from '@/components/ui/LoadingSkeleton'
import { createClient } from '@/lib/supabase/client'

interface Profile {
  id: string
  magical_name: string
  house: 'gryffindor' | 'hufflepuff' | 'ravenclaw' | 'slytherin'
}

export default function PlayPage() {
  const router = useRouter()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [spectatorCode, setSpectatorCode] = useState('')
  const [spectatorError, setSpectatorError] = useState('')
  const [watching, setWatching] = useState(false)
  const [teamComingSoon, setTeamComingSoon] = useState(false)

  const supabase = createClient()

  useEffect(() => {
    loadProfile()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps -- initial page load only

  const loadProfile = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      
      if (!user) {
        router.push('/login')
        return
      }

      const { data: profileData } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

      if (profileData) {
        setProfile(profileData)
      }
    } catch (error) {
      console.error('Error loading profile:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  const handleSolo = () => {
    router.push('/room/create?solo=true')
  }

  const handleTeam = () => {
    setTeamComingSoon(true)
  }

  const handleSpectate = async (event: React.FormEvent) => {
    event.preventDefault()
    const code = spectatorCode.trim().toUpperCase()
    if (!code) return
    setWatching(true)
    setSpectatorError('')

    const { data: room, error } = await supabase
      .from('rooms')
      .select('id, room_code, status')
      .eq('room_code', code)
      .maybeSingle()

    if (error || !room) {
      setSpectatorError('No match was found with that code. Check the code and try again.')
      setWatching(false)
      return
    }

    const { data: teams } = await supabase
      .from('teams')
      .select('team_number, name')
      .eq('room_id', room.id)
      .order('team_number')

    const team1 = teams?.find(team => team.team_number === 1)?.name || 'Team 1'
    const team2 = teams?.find(team => team.team_number === 2)?.name || 'Team 2'
    router.push(`/game/${room.room_code}?spectator=true&team=1&t1=${encodeURIComponent(team1)}&t2=${encodeURIComponent(team2)}`)
  }

  if (loading) {
    return (
      <MagicalBackground>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="mb-8 text-center animate-pulse">
            <div className="h-10 w-64 bg-gradient-to-r from-amber-500/20 to-amber-500/10 rounded mx-auto mb-2" />
            <div className="h-5 w-48 bg-slate-700/50 rounded mx-auto" />
          </div>
          <LoadingSkeleton variant="list" />
        </div>
      </MagicalBackground>
    )
  }

  if (!profile) {
    return null
  }

  return (
    <MagicalBackground>
      <MagicalNavbar
        magicalName={profile.magical_name}
        house={profile.house}
        onLogout={handleLogout}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8 text-center">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-amber-400 to-amber-600 bg-clip-text text-transparent mb-2">
            ⚡ Choose Your Mode
          </h1>
          <p className="text-slate-400">Select gameplay style to begin</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          <RoomCard
            title="SOLO"
            description="Control all 7 positions of your team. Face off against another solo player."
            icon="🧙‍♂️"
            onClick={handleSolo}
          />
          <RoomCard
            title="TEAM"
            description="Join a team of 7 players. Each player controls one position."
            icon="👥"
            onClick={handleTeam}
          />
          <RoomCard
            title="SPECTATOR"
            description="Watch an active Quidditch match live, with the full board and no player controls."
            icon="🔭"
            onClick={() => document.getElementById('spectator-code')?.focus()}
          />
        </div>

        <MagicalCard className="mx-auto mt-8 max-w-2xl" glow>
          <form onSubmit={handleSpectate} className="flex flex-col gap-3 sm:flex-row sm:items-end">
            <label className="flex-1 text-sm font-black tracking-wide text-amber-200">
              SPECTATOR MATCH CODE
              <input
                id="spectator-code"
                value={spectatorCode}
                onChange={event => setSpectatorCode(event.target.value.toUpperCase())}
                placeholder="QUID-4821"
                className="mt-2 w-full rounded-xl border border-amber-300/30 bg-black/30 px-4 py-3 text-base font-bold tracking-wider text-white outline-none transition placeholder:text-slate-500 focus:border-amber-300"
              />
            </label>
            <button type="submit" disabled={watching} className="rounded-xl border border-amber-300/50 bg-[#0e4a86]/80 px-6 py-3 font-black text-white transition hover:bg-[#1462ab] disabled:opacity-50">
              {watching ? 'Opening…' : 'Watch Match'}
            </button>
          </form>
          {spectatorError && <p className="mt-3 text-sm font-semibold text-rose-300">{spectatorError}</p>}
          <p className="mt-3 text-xs text-slate-300">Spectators can watch active or completed matches but cannot make gameplay changes.</p>
        </MagicalCard>

        <div className="mt-12 max-w-4xl mx-auto">
          <MagicalCard>
            <h2 className="text-2xl font-bold text-amber-400 mb-4">📜 Game Rules</h2>
            <div className="space-y-4 text-slate-300">
              <div>
                <h3 className="font-semibold text-white mb-1">Solo Mode</h3>
                <p className="text-sm">One player controls all 7 positions (Keeper, 3 Chasers, 2 Beaters, Seeker) of their team. Maximum 2 players per match.</p>
              </div>
              <div>
                <h3 className="font-semibold text-white mb-1">Team Mode</h3>
                <p className="text-sm">7 players per team, each controlling one position. Maximum 14 players per match. Team captain must confirm team readiness.</p>
              </div>
            </div>
          </MagicalCard>
        </div>
      </div>

      {teamComingSoon && (
        <div
          className="fixed inset-0 z-[90] flex items-center justify-center bg-slate-950/85 px-4 backdrop-blur-md"
          role="dialog"
          aria-modal="true"
          aria-labelledby="team-coming-soon-title"
          onClick={() => setTeamComingSoon(false)}
        >
          <div
            className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-amber-300/40 bg-gradient-to-br from-slate-950 via-[#111b3d] to-purple-950/80 p-8 text-center shadow-[0_0_80px_rgba(168,85,247,0.35)] animate-in fade-in zoom-in duration-300"
            onClick={event => event.stopPropagation()}
          >
            <div className="pointer-events-none absolute -left-16 -top-16 h-40 w-40 rounded-full bg-purple-500/20 blur-3xl animate-pulse" />
            <div className="pointer-events-none absolute -bottom-20 -right-10 h-48 w-48 rounded-full bg-amber-400/20 blur-3xl animate-pulse" />
            <div className="relative">
              <div className="mx-auto mb-5 flex h-20 w-20 items-center justify-center rounded-full border border-amber-200/50 bg-gradient-to-br from-purple-500 to-amber-400 text-4xl shadow-[0_0_35px_rgba(251,191,36,0.45)] animate-bounce">
                ⚡
              </div>
              <p className="mb-2 text-xs font-black tracking-[0.3em] text-amber-300">THE NEXT MATCH FORMAT</p>
              <h2 id="team-coming-soon-title" className="mb-3 text-4xl font-black text-white">
                Team Mode is Coming Soon
              </h2>
              <p className="mx-auto max-w-md text-base leading-7 text-slate-300">
                Assemble your full squad, choose your position, and play together in the next magical release.
              </p>
              <div className="my-7 flex items-center justify-center gap-2" aria-hidden="true">
                {[0, 1, 2, 3, 4].map(index => (
                  <span
                    key={index}
                    className="h-2 w-2 rounded-full bg-amber-300 shadow-[0_0_12px_rgba(253,224,71,0.8)] animate-pulse"
                    style={{ animationDelay: `${index * 140}ms` }}
                  />
                ))}
              </div>
              <button
                type="button"
                onClick={() => setTeamComingSoon(false)}
                className="rounded-xl border border-amber-200/50 bg-amber-400 px-8 py-3 font-black text-slate-950 shadow-[0_0_25px_rgba(251,191,36,0.3)] transition hover:-translate-y-0.5 hover:bg-amber-300"
              >
                Continue Solo
              </button>
            </div>
          </div>
        </div>
      )}
    </MagicalBackground>
  )
}
