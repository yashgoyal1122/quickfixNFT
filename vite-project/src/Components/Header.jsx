import React from 'react'
// import { TokenRounded } from '@mui/icons-material'
import Vite from '../../public/vite.svg'
function Header() {
  return (
    <div className='flex justify-between px-5 py-5 backdrop-blur-lg shadow-lg'>
        <div className='flex items-center gap-x-2'>
            <img src={Vite} alt='icon' className='grayscale hover:grayscale-0 duration-500 ease-in-out cursor-pointer'/>
            <h1 className='text-[30px]'>QuickFix NFT</h1>
        </div>
        <div className='flex justify-between w-4/12'>
        <input type="text" className='border-[#232323] border px-5 rounded-md focus:outline-none w-4/6'/>
        <button className='bg-black py-3 px-5 text-white rounded-lg hover:bg-white hover:text-black hover:ring-1 hover:ring-inset hover:ring-black duration-300 ease-in-out'>Connect Wallet</button>
        </div>
    </div>
  )
}

export default Header