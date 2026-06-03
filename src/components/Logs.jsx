import { useState, useEffect, useRef } from 'react'
import { invoke } from '@tauri-apps/api/tauri'
import './Logs.css'

export default function Logs() {
  const [logs, setLogs] = useState([])
  const [autoScroll, setAutoScroll] = useState(true)
  const logsEndRef = useRef(null)

  useEffect(() => {
    fetchLogs()
    const interval = setInterval(fetchLogs, 2000)
    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    if (autoScroll && logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: 'smooth' })
    }
  }, [logs, autoScroll])

  const fetchLogs = async () => {
    try {
      const result = await invoke('get_daemon_logs', { lines: 100 })
      setLogs(result)
    } catch (error) {
      console.error('Erro ao buscar logs:', error)
    }
  }

  const handleClearLogs = async () => {
    try {
      await invoke('clear_daemon_logs')
      setLogs([])
    } catch (error) {
      alert('Erro ao limpar logs: ' + error)
    }
  }

  return (
    <div className="logs">
      <div className="logs-header">
        <h2>📝 Logs do Daemon</h2>
        <div className="logs-controls">
          <label className="checkbox-label">
            <input
              type="checkbox"
              checked={autoScroll}
              onChange={(e) => setAutoScroll(e.target.checked)}
            />
            <span>Auto-scroll</span>
          </label>
          <button className="btn btn-secondary" onClick={fetchLogs}>
            🔄 Atualizar
          </button>
          <button className="btn btn-danger" onClick={handleClearLogs}>
            🗑️ Limpar
          </button>
        </div>
      </div>

      <div className="logs-container">
        {logs.length === 0 ? (
          <div className="logs-empty">Nenhum log disponível</div>
        ) : (
          <pre className="logs-content">
            {logs.map((log, index) => (
              <div key={index} className="log-line">
                {log}
              </div>
            ))}
            <div ref={logsEndRef} />
          </pre>
        )}
      </div>

      <div className="logs-info">
        <small>Total de linhas: {logs.length}</small>
      </div>
    </div>
  )
}
