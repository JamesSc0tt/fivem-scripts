/* 'links' the js with the Nui message from main.lua */
window.addEventListener('message', (event) => {
  //document.querySelector("#logo").innerHTML = " "
  var item = event.data;
  if (item !== undefined) {
    if (item.type === 'prompt') {
      let prompt = document.getElementById('prompt')
      if (item.inService === false) {
        prompt.children[0].innerHTML = `Press <span class='green'>E</span> to rent a cab. (<span class='red'>-$${item.rentalPrice}</span>)`
        prompt.children[1].innerHTML = `Press <span class='yellow'>H</span> to clock in.`
      } else {
        prompt.children[0].innerHTML = `Press <span class='green'>E</span> to return your cab. (<span class='green'>+$${item.returnPrice}</span>)`
        prompt.children[1].innerHTML = `Press <span class='red'>H</span> to rent another cab. (<span class='red'>-$${item.rentalPrice}</span>)`
      }

      /* if the display is true, it will show */
      if (item.display === true) {
        prompt.classList.remove('hidden')
      /* if the display is false, it will hide */
      } else {
        prompt.classList.add('hidden');
      }
    } else if (item.type === 'status') {
      if (item.display === true && item.status) {
        let ptag = document.getElementById('status').firstElementChild;
        ptag.classList.remove('red', 'yellow', 'green')
        console.log(JSON.stringify(item))
      
        switch (item.status) {
          case 'Waiting':
            ptag.innerHTML = 'Wait for a customer to request a ride';
            ptag.classList.add('yellow');
            break;
          case 'CustDead':
            ptag.innerHTML = 'Your customer has died. Please wait for another';
            ptag.classList.add('red');
            break;
          case 'DropOff':
            ptag.innerHTML = 'Drop off the customer at the destination';
            ptag.classList.add('yellow');
            break;
          case 'OutVeh':
            ptag.innerHTML = 'Get in your taxi to continue the job';
            ptag.classList.add('red');
            break;
          case 'WillFire':
            ptag.innerHTML = 'Get back to your taxi!';
            ptag.classList.add('red');
            break;
          case 'Success':
            ptag.innerHTML = `Customer dropped off. Total payment is $${item.args[0]}`;
            ptag.classList.add('green');
            break;
          case 'PickUp':
            ptag.innerHTML = 'Pick up the customer';
            ptag.classList.add('green');
            break;
        }

        document.getElementById('status').classList.remove('hidden')
      } else {
        document.getElementById('status').classList.add('hidden');
      }
    }
  }
});
