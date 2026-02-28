import React from 'react';
import { BrowserRouter, Routes, Route, Link, useLocation } from 'react-router-dom';
import { ShieldCheck, User } from 'lucide-react';
import EmployeePortal from './EmployeePortal';
import ManagerPortal from './ManagerPortal';

function NavLinks() {
  const location = useLocation();
  
  return (
    <div className="nav-links">
      <Link 
        to="/" 
        className={`nav-link ${location.pathname === '/' ? 'active' : ''}`}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <User size={18} />
          <span>Employee Portal</span>
        </div>
      </Link>
      <Link 
        to="/manager" 
        className={`nav-link ${location.pathname === '/manager' ? 'active' : ''}`}
      >
         <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <ShieldCheck size={18} />
          <span>Manager Dashboard</span>
        </div>
      </Link>
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <div className="app-container">
        <nav className="navbar">
          <h1>⚡ Serverless Certs</h1>
          <NavLinks />
        </nav>
        
        <main className="main-content">
          <Routes>
            <Route path="/" element={<EmployeePortal />} />
            <Route path="/manager" element={<ManagerPortal />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}

export default App;
