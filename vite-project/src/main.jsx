import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'
import { createBrowserRouter, createRoutesFromElements, Route, RouterProvider } from 'react-router-dom'
import Question from './Pages/Question.jsx'
import Collection from './Pages/Collection.jsx'
import Sell from './Pages/Sell.jsx'
import Withdraw from './Pages/Withdraw.jsx'



const router = createBrowserRouter(
  createRoutesFromElements(
    <Route path='/' element={<App />}>
      <Route path='/' element={<Question />}/>
      <Route path='sell' element={<Sell />}/>
      <Route path='collection' element={<Collection />}/>
      <Route path='withdraw' element={<Withdraw />}/>
    </Route>
  )
)
ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>,
)
