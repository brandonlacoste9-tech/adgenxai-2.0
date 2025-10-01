import { BrowserRouter, Routes, Route } from 'react-router-dom'
import './App.css'

function Dashboard() {
  return (
    <div>
      <h1>AdGenXAI 2.0 Dashboard</h1>
      <p>Welcome to the AdGenXAI Dashboard</p>
    </div>
  )
}

function App() {
  return (
    <BrowserRouter>
      <div className="App">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/dashboard" element={<Dashboard />} />
        </Routes>
        <footer>
          <p>
            <a 
              href="https://github.com/brandonlacoste9-tech/adgenxai-2.0" 
              target="_blank" 
              rel="noopener noreferrer"
            >
              View on GitHub
            </a>
          </p>
        </footer>
      </div>
    </BrowserRouter>
  )
}

export default App
