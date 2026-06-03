import { useState, useEffect } from 'react'
import { invoke } from '@tauri-apps/api/tauri'
import './StatusBar.css'

export default function StatusBar() {
  const [status, setStatus] = useState(null)

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const result = await invoke('get_daemon_status')
        setStatus(result)
      } catch (error) {
        console.error('Erro ao buscar status:', error)
      }
    }

    fetchStatus()
    const interval = setInterval(fetchStatus, 1000)
    return () => clearInterval(interval)
  }, [])

  if (!status) return null

  const statusText = status.running
    ? `📊 ${status.renewal_progress || 0}% | ⏱️ ${status.minutes_until_reset || 0}m`
    : '⚪ Inativo'

  return (
    <div className="status-bar">
      <span className="status-text">{statusText}</span>
    </div>
  )
}
