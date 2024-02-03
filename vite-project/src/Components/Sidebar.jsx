import React from 'react'
import SideElements from './SideElements'
import { NavLink } from 'react-router-dom'
// import { StickyNote, Tag, Settings, CircleDollarSign } from 'lucide'

function Sidebar() {
  return (
    <div className='border flex flex-col max-w-[250px] h-full py-5'>
        <SideElements heading='Trading' arr={[{tabText: 'Questions/Answers catalogue', href: '/' }, {tabText: 'Sell NFTs', href: 'sell'}]}/>

        <SideElements heading='Administration' arr={[{tabText: 'AnswerNFT collection', href: 'collection'}]} />

        <SideElements heading='Withdraw(Admin Only)' arr={[{tabText: 'Withdraw', href: 'withdraw'}]} />
    </div>
  )
}

export default Sidebar