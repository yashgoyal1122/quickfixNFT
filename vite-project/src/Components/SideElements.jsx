import React from 'react'

function SideElements({heading, arr}) {
  return (
    <div className='border-b'>
        <h1 className='text-[25px] px-3 my-2'>{heading}</h1>
        <div>
            {arr.map((elem, index) => {
                
                return(
                    <div key={index} className='flex py-3 gap-x-2 hover:bg-slate-100 px-3 duration-500 ease-in-out'>
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-move-right"><path d="M18 8L22 12L18 16"/><path d="M2 12H22"/></svg>
                        <span>{elem.tabText}</span>
                    </div>
                )
            })}
        </div>
    </div>
  )
}

export default SideElements