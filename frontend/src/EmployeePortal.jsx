import React, { useState } from 'react';
import { Send, Search, Loader2, CheckCircle, Clock, XCircle } from 'lucide-react';

// API Gateway endpoint URL (from terraform output)
const API_URL = 'https://p94uphzb2m.execute-api.ap-south-1.amazonaws.com';

export default function EmployeePortal() {
  const [activeTab, setActiveTab] = useState('submit'); // 'submit' | 'status'
  
  // Submit state
  const [formData, setFormData] = useState({ name: '', course: '', cost: '' });
  const [submitLoading, setSubmitLoading] = useState(false);
  const [submitResult, setSubmitResult] = useState(null);
  
  // Status check state
  const [checkId, setCheckId] = useState('');
  const [checkLoading, setCheckLoading] = useState(false);
  const [checkResult, setCheckResult] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitLoading(true);
    setSubmitResult(null);

    try {
      const resp = await fetch(`${API_URL}/request`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.name,
          course: formData.course,
          cost: parseFloat(formData.cost)
        })
      });
      
      const data = await resp.json();
      setSubmitResult({ success: resp.ok, data });
      if (resp.ok) setFormData({ name: '', course: '', cost: '' });
    } catch (err) {
      setSubmitResult({ success: false, data: { error: err.message } });
    } finally {
      setSubmitLoading(false);
    }
  };

  const handleCheck = async (e) => {
    e.preventDefault();
    if (!checkId.trim()) return;
    
    setCheckLoading(true);
    setCheckResult(null);

    try {
      const resp = await fetch(`${API_URL}/request/${checkId.trim()}`);
      const data = await resp.json();
      setCheckResult({ success: resp.ok, data });
    } catch (err) {
      setCheckResult({ success: false, data: { error: err.message } });
    } finally {
      setCheckLoading(false);
    }
  };

  return (
    <div className="glass-card">
      <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem' }}>
        <button 
          onClick={() => { setActiveTab('submit'); setSubmitResult(null); }}
          className="btn" 
          style={{ background: activeTab === 'submit' ? 'var(--primary)' : 'rgba(255,255,255,0.1)' }}
        >
          Submit Request
        </button>
        <button 
          onClick={() => { setActiveTab('status'); setCheckResult(null); }}
          className="btn"
          style={{ background: activeTab === 'status' ? 'var(--primary)' : 'rgba(255,255,255,0.1)' }}
        >
          Check Status
        </button>
      </div>

      {activeTab === 'submit' ? (
        <div>
          <h2>New Certification Request</h2>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Employee Name</label>
              <input required className="form-input" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} placeholder="e.g. Alice" />
            </div>
            <div className="form-group">
              <label>Certification Course</label>
              <input required className="form-input" value={formData.course} onChange={e => setFormData({...formData, course: e.target.value})} placeholder="e.g. AWS Certified Developer" />
            </div>
            <div className="form-group">
              <label>Cost (USD)</label>
              <input required type="number" min="0" className="form-input" value={formData.cost} onChange={e => setFormData({...formData, cost: e.target.value})} placeholder="150" />
            </div>
            <button type="submit" className="btn" disabled={submitLoading}>
              {submitLoading ? <Loader2 className="spinner" /> : <Send size={18} />}
              Submit Request
            </button>
          </form>

          {submitResult && (
            <div className="result-box" style={{ borderColor: submitResult.success ? 'var(--secondary)' : 'var(--error)' }}>
              {submitResult.success ? (
                <>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--secondary)', marginBottom: '10px' }}>
                    <CheckCircle size={20} /> <span style={{fontWeight: 600}}>Successfully Submitted!</span>
                  </div>
                  <p style={{fontSize: '0.9rem', color: 'var(--text-muted)'}}>Please save this Request ID to check your status later:</p>
                  <div className="copy-text">{submitResult.data.requestId}</div>
                </>
              ) : (
                <div style={{ color: 'var(--error)' }}>Error: {submitResult.data.error || 'Failed to submit'}</div>
              )}
            </div>
          )}
        </div>
      ) : (
        <div>
          <h2>Check Request Status</h2>
          <form onSubmit={handleCheck}>
            <div className="form-group">
              <label>Request ID</label>
              <input required className="form-input" value={checkId} onChange={e => setCheckId(e.target.value)} placeholder="Enter your UUID..." />
            </div>
            <button type="submit" className="btn" disabled={checkLoading}>
              {checkLoading ? <Loader2 className="spinner" /> : <Search size={18} />}
              Verify Status
            </button>
          </form>

          {checkResult && (
            <div className="result-box" style={{ borderColor: checkResult.success ? 'var(--secondary)' : 'var(--error)' }}>
              {checkResult.success ? (
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h3 style={{color: 'white', fontSize: '1.2rem'}}>{checkResult.data.course}</h3>
                    <span className={`status-badge status-${checkResult.data.status}`}>
                      {checkResult.data.status === 'PENDING' && <Clock size={14} style={{marginRight: '4px'}} />}
                      {checkResult.data.status === 'APPROVED' && <CheckCircle size={14} style={{marginRight: '4px'}} />}
                      {checkResult.data.status === 'REJECTED' && <XCircle size={14} style={{marginRight: '4px'}} />}
                      {checkResult.data.status}
                    </span>
                  </div>
                  <div className="status-info-grid">
                    <span className="info-label">Employee:</span>
                    <span className="info-value">{checkResult.data.name}</span>
                    <span className="info-label">Cost:</span>
                    <span className="info-value">${checkResult.data.cost}</span>
                  </div>
                </div>
              ) : (
                <div style={{ color: 'var(--error)' }}>{checkResult.data.error || 'Request Not Found'}</div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
