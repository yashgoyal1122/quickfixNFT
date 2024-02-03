import React from 'react'
import SideElements from './SideElements'
import { StickyNote, Tag, Settings, CircleDollarSign } from 'lucide'

function Sidebar() {
  return (
    <div className='border flex flex-col max-w-[250px] h-full py-5'>
        <SideElements heading='Trading' arr={[{imageUrl: StickyNote, tabText: 'Questions/Answers catalogue' }, {imageUrl: Tag, tabText: 'Sell NFTs'}]}/>

        <SideElements heading='Administration' arr={[{imageUrl: Settings, tabText: 'AnswerNFT collection'}]} />

        <SideElements heading='Withdraw(Admin Only)' arr={[{imageUrl: CircleDollarSign, tabText: 'Withdraw'}]} />
    </div>
  )
}

export default Sidebar