import { useState, useEffect } from 'react'
import { invoke } from '@tauri-apps/api/tauri'
import { appWindow } from '@tauri-apps/api/window'
import { listen } from '@tauri-apps/api/event'
import Dashboard from './components/Dashboard'
import Settings from './components/Settings'
import Logs from './components/Logs'
import './App.css'

export default function App() {
  const [currentView, setCurrentView] = useState('dashboard')
  const [status, setStatus] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    fetchStatus()
    const interval = setInterval(fetchStatus, 5000)

    const unlistenPromise = listen('tray_action', (event) => {
      if (event.payload === 'start_daemon') {
        handleStartDaemon()
      } else if (event.payload === 'stop_daemon') {
        handleStopDaemon()
      }
    })

    return () => {
      clearInterval(interval)
      unlistenPromise.then(unlisten => unlisten())
    }
  }, [])

  const fetchStatus = async () => {
    try {
      const result = await invoke('get_daemon_status')
      setStatus(result)
    } catch (error) {
      console.error('Erro ao buscar status:', error)
    }
  }

  const handleStartDaemon = async () => {
    setLoading(true)
    try {
      await invoke('start_daemon')
      await fetchStatus()
    } catch (error) {
      alert('Erro ao iniciar daemon: ' + error)
    } finally {
      setLoading(false)
    }
  }

  const handleStopDaemon = async () => {
    setLoading(true)
    try {
      await invoke('stop_daemon')
      await fetchStatus()
    } catch (error) {
      alert('Erro ao parar daemon: ' + error)
    } finally {
      setLoading(false)
    }
  }

  const handleRestartDaemon = async () => {
    setLoading(true)
    try {
      await invoke('restart_daemon')
      await fetchStatus()
    } catch (error) {
      alert('Erro ao reiniciar daemon: ' + error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="app-container">
      <header className="app-header">
        <h1>⚡ Claude Auto-Renew</h1>
        <div className="header-status">
          {status && (
            <div className={`status-badge ${status.running ? 'active' : 'inactive'}`}>
              {status.running ? '🟢 Ativo' : '🔴 Inativo'}
            </div>
          )}
        </div>
      </header>

      <nav className="app-nav">
        <button
          className={`nav-button ${currentView === 'dashboard' ? 'active' : ''}`}
          onClick={() => setCurrentView('dashboard')}
        >
          📊 Dashboard
        </button>
        <button
          className={`nav-button ${currentView === 'settings' ? 'active' : ''}`}
          onClick={() => setCurrentView('settings')}
        >
          ⚙️ Configurações
        </button>
        <button
          className={`nav-button ${currentView === 'logs' ? 'active' : ''}`}
          onClick={() => setCurrentView('logs')}
        >
          📝 Logs
        </button>
      </nav>

      <main className="app-content">
        {currentView === 'dashboard' && (
          <Dashboard
            status={status}
            loading={loading}
            onStart={handleStartDaemon}
            onStop={handleStopDaemon}
            onRestart={handleRestartDaemon}
            onRefresh={fetchStatus}
          />
        )}
        {currentView === 'settings' && <Settings status={status} onSettingsChange={fetchStatus} />}
        {currentView === 'logs' && <Logs />}
      </main>

      <footer className="app-footer">
        <button
          className="footer-button quit-button"
          onClick={() => appWindow.hide()}
        >
          ✕ Fechar
        </button>
      </footer>
    </div>
  )
}
