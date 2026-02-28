import React, { useState } from 'react';
import { ShieldAlert, CheckCircle, XCircle, Loader2 } from 'lucide-react';

const API_URL = 'https://p94uphzb2m.execute-api.ap-south-1.amazonaws.com';

export default function ManagerPortal() {
  const [formData, setFormData] = useState({ requestId: '', taskToken: '' });
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);

  const handleDecision = async (decision) => {
    if (!formData.requestId || !formData.taskToken) {
      setResult({ success: false, message: 'Please provide both Request ID and Task Token.' });
      return;
    }

    setLoading(true);
    setResult(null);

    try {
      const resp = await fetch(`${API_URL}/approval`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          requestId: formData.requestId.trim(),
          taskToken: formData.taskToken.trim(),
          decision: decision
        })
      });
      
      const data = await resp.json();
      setResult({ success: resp.ok, message: data.message || data.error });
      if (resp.ok) setFormData({ requestId: '', taskToken: '' });
    } catch (err) {
      setResult({ success: false, message: err.message });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="glass-card" style={{ maxWidth: '600px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '1.5rem' }}>
        <ShieldAlert size={28} color="var(--primary)" />
        <h2>Manager Approval Dashboard</h2>
      </div>
      
      <p style={{ color: 'var(--text-muted)', marginBottom: '2rem', fontSize: '0.9rem', lineHeight: '1.5' }}>
        Review certification requests and authorize reimbursements. You must obtain the Task Token from the workflow notification to cryptographically authorize this decision.
      </p>

      <div className="form-group">
        <label>Request ID</label>
        <input 
          required 
          className="form-input" 
          value={formData.requestId} 
          onChange={e => setFormData({...formData, requestId: e.target.value})} 
          placeholder="e.g. 58cdc613-faf7-..." 
        />
      </div>

      <div className="form-group">
        <label>Unique Task Token</label>
        <textarea 
          required 
          className="form-input" 
          rows="4" 
          value={formData.taskToken} 
          onChange={e => setFormData({...formData, taskToken: e.target.value})} 
          placeholder="Paste the extremely long Step Functions task token here..." 
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '2rem' }}>
        <button 
          onClick={() => handleDecision('REJECTED')}
          className="btn btn-danger" 
          disabled={loading}
        >
          {loading ? <Loader2 className="spinner" size={18} /> : <XCircle size={18} />}
          Reject Request
        </button>
        <button 
          onClick={() => handleDecision('APPROVED')}
          className="btn btn-success" 
          disabled={loading}
        >
          {loading ? <Loader2 className="spinner" size={18} /> : <CheckCircle size={18} />}
          Approve & Authorize
        </button>
      </div>

      {result && (
        <div className="result-box" style={{ borderColor: result.success ? 'var(--secondary)' : 'var(--error)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: result.success ? 'var(--secondary)' : 'var(--error)' }}>
            {result.success ? <CheckCircle size={20} /> : <XCircle size={20} />}
            <span style={{fontWeight: 600}}>
              {result.success ? 'Success' : 'Error'}
            </span>
          </div>
          <p style={{ marginTop: '0.5rem', color: 'white' }}>{result.message}</p>
        </div>
      )}
    </div>
  );
}
