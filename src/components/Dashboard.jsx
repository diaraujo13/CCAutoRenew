import './Dashboard.css'

export default function Dashboard({ status, loading, onStart, onStop, onRestart, onRefresh }) {
  if (!status) {
    return (
      <div className="dashboard">
        <div className="loading">Carregando...</div>
      </div>
    )
  }

  const getProgressColor = (percentage) => {
    if (percentage >= 60) return '#16a34a'
    if (percentage >= 30) return '#ea580c'
    return '#dc2626'
  }

  return (
    <div className="dashboard">
      <section className="card">
        <h2>Status do Daemon</h2>
        <div className="status-info">
          <div className={`status-indicator ${status.running ? 'running' : 'stopped'}`}>
            {status.running ? '🟢' : '🔴'}
          </div>
          <div>
            <p className="status-text">
              {status.running ? 'Daemon está ativo' : 'Daemon está inativo'}
            </p>
            <p className="status-pid">PID: {status.pid || 'N/A'}</p>
          </div>
        </div>
      </section>

      {status.running && (
        <>
          <section className="card">
            <h2>Próxima Renovação</h2>
            <div className="renewal-info">
              <div className="time-remaining">
                <span className="time-value">{status.minutesUntilReset || '--'}</span>
                <span className="time-label">minutos</span>
              </div>
              <div className="progress-bar">
                <div
                  className="progress-fill"
                  style={{
                    width: `${status.renewalProgress || 0}%`,
                    backgroundColor: getProgressColor(status.renewalProgress || 0),
                  }}
                />
              </div>
              <p className="next-renewal">
                Próxima renovação em: {status.nextRenewalTime || 'calculando...'}
              </p>
            </div>
          </section>

          <section className="card">
            <h2>Informações</h2>
            <div className="info-grid">
              <div className="info-item">
                <span className="info-label">Horário de Início:</span>
                <span className="info-value">{status.startTime || 'Sem limite'}</span>
              </div>
              <div className="info-item">
                <span className="info-label">Horário de Parada:</span>
                <span className="info-value">{status.stopTime || 'Sem limite'}</span>
              </div>
              <div className="info-item">
                <span className="info-label">Última Atividade:</span>
                <span className="info-value">{status.lastActivity || 'Nunca'}</span>
              </div>
              <div className="info-item">
                <span className="info-label">Modo ccusage:</span>
                <span className="info-value">{status.ccusageEnabled ? 'Ativo' : 'Desativo'}</span>
              </div>
            </div>
          </section>
        </>
      )}

      <section className="card actions">
        <h2>Ações</h2>
        <div className="button-group">
          {!status.running ? (
            <button
              className="btn btn-primary"
              onClick={onStart}
              disabled={loading}
            >
              ▶️ Iniciar
            </button>
          ) : (
            <>
              <button
                className="btn btn-warning"
                onClick={onStop}
                disabled={loading}
              >
                ⏸️ Parar
              </button>
              <button
                className="btn btn-secondary"
                onClick={onRestart}
                disabled={loading}
              >
                🔄 Reiniciar
              </button>
            </>
          )}
          <button
            className="btn btn-gray"
            onClick={onRefresh}
            disabled={loading}
          >
            🔄 Atualizar
          </button>
        </div>
      </section>
    </div>
  )
}
