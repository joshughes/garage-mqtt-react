/** @jsx React.DOM */

var HelloWorld = React.createClass({

  getDefaultProps: function() {
    var _ws   = new WebSocket("ws://192.168.1.107:5000/")
        _this = this
    _ws.onmessage = function (evt){
      var received_msg = JSON.parse(evt.data);
      console.log("OMG A MESSAGE");
      console.log(received_msg.command);
      if(received_msg.command == "open"){
        console.log('OPEN');
        _this.setState({open: true})
        console.log(JSON.stringify(received_msg));
      }
      else if(received_msg.command == "closed"){
        console.log('CLOSED');
        _this.setState({open: false})
        console.log(JSON.stringify(received_msg));
      }
    };

    return {
      ws: _ws
    };
  },
  getInitialState: function(){
    var _this = this;
    this.props.ws.onmessage = function (evt){
      var received_msg = JSON.parse(evt.data);
      console.log("OMG A MESSAGE");
      console.log(received_msg.command);
      if(received_msg.command == "open"){
        console.log('OPEN');
        _this.setState({open: true});
        console.log(JSON.stringify(received_msg));
      }
      else if(received_msg.command == "closed"){
        console.log('CLOSED');
        _this.setState({open: false});
        console.log(JSON.stringify(received_msg));
      }
    };
    return({
      name: "doooo",
      open: false,
      message: []
    });
  },

  componentDidMount: function() {
    $('#door-state').bootstrapToggle();
    var _this = this;
    //this.toggleDoor();
    $('#door-state').change(function() {
      if(_this.state.open != $(this).prop('checked')){
        _this.handleChange($(this).prop('checked'));
      }
    });
  },

  sendCommand: function(command){
    var message = {
      command: command
    };
    this.props.ws.send(JSON.stringify(message));
  },

  toggleDoor: function(){
    if(this.state.open){
      console.log("The state is open in toggleDoor");
      $('#door-state').bootstrapToggle('on');
    }
    else {
      console.log("The state is closed in toggleDoor");
      $('#door-state').bootstrapToggle('off');
      console.log("made it here")
    }
  },

  handleChange: function(door_state){
    if(door_state){
      this.sendCommand('open')
    }
    else {
      this.sendCommand('close')
    }
  },

  render() {
    this.toggleDoor();
    return (
      <div className="row">
        <div className="col-sm-4">
          <form role="form">
            <div className="form-group">
              <label htmlFor="email">{this.state.open.toString()}</label>
              <input type="email" className="form-control" id="email"/>
            </div>
            <div className="form-group">
              <label>
                Door State:
                <input id="door-state"
                       type="checkbox"
                       data-toggle="toggle"
                       data-on="Open"
                       data-off="Closed"/>
              </label>
            </div>
          </form>
        </div>
      </div>
    );
  }

});
