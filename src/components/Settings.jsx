import { useState } from 'react'
import { invoke } from '@tauri-apps/api/tauri'
import './Settings.css'

export default function Settings({ status, onSettingsChange }) {
  const [startTime, setStartTime] = useState(status?.startTime || '')
  const [stopTime, setStopTime] = useState(status?.stopTime || '')
  const [customMessage, setCustomMessage] = useState(status?.customMessage || '')
  const [loading, setLoading] = useState(false)

  const handleSave = async () => {
    setLoading(true)
    try {
      await invoke('save_settings', {
        startTime,
        stopTime,
        customMessage,
      })
      onSettingsChange()
      alert('Configurações salvas com sucesso!')
    } catch (error) {
      alert('Erro ao salvar configurações: ' + error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="settings">
      <section className="card">
        <h2>Horários</h2>
        <div className="form-group">
          <label htmlFor="startTime">Horário de Início</label>
          <input
            id="startTime"
            type="time"
            value={startTime}
            onChange={(e) => setStartTime(e.target.value)}
            placeholder="HH:MM"
          />
          <small>Deixe em branco para começar imediatamente</small>
        </div>

        <div className="form-group">
          <label htmlFor="stopTime">Horário de Parada</label>
          <input
            id="stopTime"
            type="time"
            value={stopTime}
            onChange={(e) => setStopTime(e.target.value)}
            placeholder="HH:MM"
          />
          <small>Deixe em branco para monitorar continuamente</small>
        </div>
      </section>

      <section className="card">
        <h2>Mensagem Customizada</h2>
        <div className="form-group">
          <label htmlFor="customMessage">Mensagem de Renovação</label>
          <textarea
            id="customMessage"
            value={customMessage}
            onChange={(e) => setCustomMessage(e.target.value)}
            placeholder="Ex: continue working on the React feature"
            rows="3"
          />
          <small>
            Deixe em branco para usar saudações aleatórias (hi, hello, hey there, etc)
          </small>
        </div>
      </section>

      <section className="card">
        <h2>Opções Avançadas</h2>
        <div className="advanced-options">
          <label className="checkbox-label">
            <input type="checkbox" defaultChecked={status?.ccusageEnabled} />
            <span>Usar ccusage para timing preciso</span>
          </label>
          <small>
            Se desabilitado, o daemon usará apenas a contagem de tempo do relógio
          </small>
        </div>
      </section>

      <div className="settings-actions">
        <button className="btn btn-primary" onClick={handleSave} disabled={loading}>
          💾 Salvar Configurações
        </button>
      </div>
    </div>
  )
}
