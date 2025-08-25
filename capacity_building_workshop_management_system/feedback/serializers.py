from rest_framework import serializers
from .models import FeedbackQuestion, FeedbackResponse

class FeedbackQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedbackQuestion
        fields = '__all__'

    def create(self, validated_data):
        request = self.context.get('request')
        return super().create(validated_data)
    
    def validate_session(self, value):
        if value is None:
            raise serializers.ValidationError("Session is required.")
        return value

# =============== FEEDBACK RESPONSE SERIALIZER ================
class FeedbackResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedbackResponse
        fields = ['id', 'participant', 'question', 'response']
        read_only_fields = ['id']

    def validate(self, data):
        question = data.get('question')
        response = data.get('response')
        if not question:
            raise serializers.ValidationError("Question must be provided.")

        response_type = question.response_type
        if response_type in ['paragraph', 'text']:
            if not isinstance(response, str):
                raise serializers.ValidationError("Response must be a string for paragraph/text type.")
        elif response_type == 'checkbox' or response_type == 'multiple_choice':
            import json
            try:
                value = json.loads(response)
                if not isinstance(value, list):
                    raise serializers.ValidationError("Checkbox/multiple_choice responses must be a JSON array.")
            except Exception:
                raise serializers.ValidationError("Checkbox/multiple_choice responses must be a valid JSON array.")
        elif response_type in ['rating', 'scale']:
            try:
                val = float(response)
            except ValueError:
                raise serializers.ValidationError("Rating/scale response must be a number.")
        elif response_type == 'yes_no':
            if response not in ['Yes', 'No', 'yes', 'no', True, False, 'true', 'false']:
                raise serializers.ValidationError("Yes/No response must be 'Yes' or 'No'.")
        else:
            if not isinstance(response, str):
                raise serializers.ValidationError("Response must be a string.")
        return data

# =============== FEEDBACK ANALYSIS SERIALIZER ================
class FeedbackAnalysisSerializer(serializers.Serializer):
    question_id = serializers.IntegerField()
    question_text = serializers.CharField()
    response_type = serializers.CharField()
    analysis_result = serializers.JSONField()
