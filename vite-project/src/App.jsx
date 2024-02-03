import React from 'react'
import Header from './Components/Header'
import Footer from './Components/Footer'
import Sidebar from './Components/Sidebar.jsx'
import { Outlet } from 'react-router-dom'

function App() {
  return (
    <div className='h-lvh'>
      <Header/>
      <div className='h-full'>
        <Sidebar />
        <Outlet />
      </div>
    </div>
  )
}

export default App