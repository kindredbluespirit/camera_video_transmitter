import asyncio
import websockets
import cv2
import numpy as np

import datetime

async def video_stream(websocket, path):
    while True:
        try:
            data = await websocket.recv()
            frame = np.frombuffer(data, dtype=np.uint8).reshape((640, 360, 3))  # Adjust the shape based on your camera resolution
            # frame = cv2.cvtColor(frame, cv2.COLOR_YUV2BGR_I420)  # Adjust color format based on your camera output format
            print(datetime.datetime.now(), frame.shape)
            cv2.imshow("Video Stream", frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        except websockets.ConnectionClosed:
            break

    cv2.destroyAllWindows()

start_server = websockets.serve(video_stream, '0.0.0.0', 8888)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
